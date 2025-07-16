import hre from "hardhat"
import { expect } from "chai"
import web3 from "@solana/web3.js"
import { getAccount, getAssociatedTokenAddress, NATIVE_MINT } from "@solana/spl-token"
import config from "../config.js"
import { deployContract, setupSPLTokens, setupATAAccounts, approveSplTokens } from "./utils.js"
import { getSecrets } from "../../neon-secrets.js";
const connection = new web3.Connection(config.svm_node[hre.globalOptions.network], "processed")

describe('LibRaydiumProgram', function() {

    console.log("\nNetwork name: " + hre.globalOptions.network)

    const RECEIPTS_COUNT = 1;
    const tokenA = NATIVE_MINT.toBase58(); // wSOL
    const WSOL = "0xc7Fc9b46e479c5Cb42f6C458D1881e55E6B7986c";
    let ethers,
        deployer,
        neonEVMUser,
        CallRaydiumCPMMProgram,
        payer,
        tokenA_Erc20ForSpl,
        tokenB,
        tokenB_Erc20ForSpl,
        poolId

    before(async function() {
        const { wallets } = await getSecrets()
        ethers = (await hre.network.connect()).ethers
        const deployment = await deployContract(wallets.owner, wallets.user1, 'CallRaydiumCPMMProgram', null);
        deployer = deployment.deployer
        neonEVMUser = deployment.user
        CallRaydiumCPMMProgram = deployment.contract
        payer = await CallRaydiumCPMMProgram.getPayer();
        tokenB = await setupSPLTokens(wallets.solanaUser1);
        console.log(tokenA, 'tokenA');
        console.log(tokenB, 'tokenB');

        // setup ATA accounts for our CallRaydiumCPMMProgram's payer
        await setupATAAccounts(
            wallets.solanaUser1,
            ethers.encodeBase58(payer),
            [tokenA, tokenB]
        );

        const erc20ForSplFactory = await ethers.getContractFactory('contracts/token/ERC20ForSpl/erc20_for_spl.sol:ERC20ForSpl', deployer);
        tokenA_Erc20ForSpl = erc20ForSplFactory.attach(WSOL);

        // deploy ERC20ForSpl interface for fresh minted spltoken tokenB
        tokenB_Erc20ForSpl = await ethers.deployContract("contracts/token/ERC20ForSpl/erc20_for_spl.sol:ERC20ForSpl", [ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenB)), 32)], wallets.owner);
        await tokenB_Erc20ForSpl.waitForDeployment();

        console.log(
            `tokenB_Erc20ForSpl deployed to ${tokenB_Erc20ForSpl.target}`
        );

        // approve tokenA and tokenB to be claimed by deployer
        let [approvedTokenA, approverTokenB] = await approveSplTokens(
            wallets.solanaUser1,
            tokenA,
            tokenB, 
            tokenA_Erc20ForSpl, 
            tokenB_Erc20ForSpl, 
            deployer
        );

        // claim tokenA
        let tx = await tokenA_Erc20ForSpl.connect(deployer).claim(
            ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(approvedTokenA)), 32),
            ethers.parseUnits('0.05', 9)
        );
        await tx.wait(RECEIPTS_COUNT);
        console.log(await tokenA_Erc20ForSpl.balanceOf(deployer.address), 'tokenA balanceOf');

        // claim tokenB
        tx = await tokenB_Erc20ForSpl.connect(deployer).claim(
            ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(approverTokenB)), 32),
            ethers.parseUnits('1000', 9)
        );
        await tx.wait(RECEIPTS_COUNT);
        console.log(await tokenB_Erc20ForSpl.balanceOf(deployer.address), 'tokenB balanceOf');

        // grant maximum approval of tokenA and tokenB to CallRaydiumCPMMProgram
        tx = await tokenA_Erc20ForSpl.connect(deployer).approve(CallRaydiumCPMMProgram.target, ethers.MaxUint256);
        await tx.wait(RECEIPTS_COUNT);

        tx = await tokenB_Erc20ForSpl.connect(deployer).approve(CallRaydiumCPMMProgram.target, ethers.MaxUint256);
        await tx.wait(RECEIPTS_COUNT);
    })

    describe('Tests', function() {
        it('createPool', async function() {
            const initialTokenABalance = await tokenA_Erc20ForSpl.balanceOf(deployer.address);
            const initialTokenBBalance = await tokenB_Erc20ForSpl.balanceOf(deployer.address);

            let tx = await CallRaydiumCPMMProgram.connect(deployer).createPool(
                tokenA_Erc20ForSpl.target,
                tokenB_Erc20ForSpl.target,
                20000000,
                10000000,
                0
            );
            await tx.wait(RECEIPTS_COUNT);
            console.log(tx, 'tx createPool');

            poolId = await CallRaydiumCPMMProgram.getCpmmPdaPoolId(
                0,
                ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenA)), 32),
                ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenB)), 32)
            )
            console.log(poolId, 'poolId');

            expect(initialTokenABalance).to.be.greaterThan(await tokenA_Erc20ForSpl.balanceOf(deployer.address));
            expect(initialTokenBBalance).to.be.greaterThan(await tokenB_Erc20ForSpl.balanceOf(deployer.address));
        });

        it('addLiquidity', async function() {
            const initialTokenABalance = await tokenA_Erc20ForSpl.balanceOf(deployer.address);
            const initialTokenBBalance = await tokenB_Erc20ForSpl.balanceOf(deployer.address);

            const poolData = await CallRaydiumCPMMProgram.getPoolData(
                0,
                ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenA)), 32),
                ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenB)), 32),
            );
            console.log(poolData, 'getPoolData');

            const poolTokens = [poolData[5], poolData[6]];
            const inputAmount = 0.0025 * 10 ** 9;
            const baseIn = false;
            const lpDivisor = (baseIn) ? 
            await CallRaydiumCPMMProgram.getTokenReserve(poolId, poolTokens[0]) : 
            await CallRaydiumCPMMProgram.getTokenReserve(poolId, poolTokens[1]);
            console.log(lpDivisor, 'lpDivisor');

            const poolLpAmount = await CallRaydiumCPMMProgram.getPoolLpAmount(poolId);
            const lpAmount = (BigInt(inputAmount) * poolLpAmount) / lpDivisor;
            console.log(lpAmount, 'lpAmount');

            const lpToAmount = await CallRaydiumCPMMProgram.lpToAmount(
                lpAmount,
                await CallRaydiumCPMMProgram.getTokenReserve(poolId, poolTokens[0]),
                await CallRaydiumCPMMProgram.getTokenReserve(poolId, poolTokens[1]),
                poolLpAmount
            );
            console.log(lpToAmount, 'lpToAmount');
            
            let tx = await CallRaydiumCPMMProgram.connect(deployer).addLiquidity(
                poolId,
                tokenA_Erc20ForSpl.target,
                tokenB_Erc20ForSpl.target,
                lpToAmount[0],
                lpToAmount[1],
                inputAmount,
                baseIn,
                100 // slippage 1%
            );
            await tx.wait(RECEIPTS_COUNT);
            console.log(tx, 'tx addLiquidity');

            expect(initialTokenABalance).to.be.greaterThan(await tokenA_Erc20ForSpl.balanceOf(deployer.address));
            expect(initialTokenBBalance).to.be.greaterThan(await tokenB_Erc20ForSpl.balanceOf(deployer.address));
        });

        it('withdrawLiquidity', async function() {
            const initialTokenABalance = await tokenA_Erc20ForSpl.balanceOf(deployer.address);
            const initialTokenBBalance = await tokenB_Erc20ForSpl.balanceOf(deployer.address);

            const getPdaLpMint = await CallRaydiumCPMMProgram.getPdaLpMint(poolId);
            const lpMintATA = await getAssociatedTokenAddress(
                new web3.PublicKey(ethers.encodeBase58(getPdaLpMint)),
                new web3.PublicKey(ethers.encodeBase58(payer)),
                true
            );
            console.log(lpMintATA, 'lpMintATA');
            
            let tx = await CallRaydiumCPMMProgram.connect(deployer).withdrawLiquidity(
                poolId,
                tokenA_Erc20ForSpl.target,
                tokenB_Erc20ForSpl.target,
                parseInt(parseInt((await getAccount(connection, lpMintATA)).amount) / 5), // withdraw 1/5th of the LP position
                100 // slippage 1%
            );
            await tx.wait(RECEIPTS_COUNT);
            console.log(tx, 'tx withdrawLiquidity');

            expect(await tokenA_Erc20ForSpl.balanceOf(deployer.address)).to.be.greaterThan(initialTokenABalance);
            expect(await tokenB_Erc20ForSpl.balanceOf(deployer.address)).to.be.greaterThan(initialTokenBBalance);
        });

        it('lockLiquidity - with metadata', async function() {
            const getPdaLpMint = await CallRaydiumCPMMProgram.getPdaLpMint(poolId);
            const lpMintATA = await getAssociatedTokenAddress(
                new web3.PublicKey(ethers.encodeBase58(getPdaLpMint)),
                new web3.PublicKey(ethers.encodeBase58(payer)),
                true
            );
            console.log(lpMintATA, 'lpMintATA');

            let tx = await CallRaydiumCPMMProgram.connect(deployer).lockLiquidity(
                poolId,
                parseInt(parseInt((await getAccount(connection, lpMintATA)).amount) / 6), // lock 1/6th of the LP position
                true,
                ethers.zeroPadValue(ethers.toBeHex(deployer.address), 32) // salt
            );
            await tx.wait(RECEIPTS_COUNT);
            console.log(tx, 'tx createPool');
        });

        it('lockLiquidity - without metadata', async function() {
            const getPdaLpMint = await CallRaydiumCPMMProgram.getPdaLpMint(poolId);
            const lpMintATA = await getAssociatedTokenAddress(
                new web3.PublicKey(ethers.encodeBase58(getPdaLpMint)),
                new web3.PublicKey(ethers.encodeBase58(payer)),
                true
            );
            console.log(lpMintATA, 'lpMintATA');

            let tx = await CallRaydiumCPMMProgram.connect(deployer).lockLiquidity(
                poolId,
                parseInt(parseInt((await getAccount(connection, lpMintATA)).amount) / 6), // lock 1/6th of the LP position
                false,
                ethers.zeroPadValue(ethers.toBeHex(CallRaydiumCPMMProgram.target), 32) // salt
            );
            await tx.wait(RECEIPTS_COUNT);
            console.log(tx, 'tx createPool');
        });

        it('swapInput', async function() {
            const initialTokenABalance = await tokenA_Erc20ForSpl.balanceOf(deployer.address);
            const initialTokenBBalance = await tokenB_Erc20ForSpl.balanceOf(deployer.address);
            
            let tx = await CallRaydiumCPMMProgram.connect(deployer).swapInput(
                poolId,
                tokenA_Erc20ForSpl.target,
                tokenB_Erc20ForSpl.target,
                200000,
                100 // slippage 1%
            );
            await tx.wait(RECEIPTS_COUNT);
            console.log(tx, 'tx swapInput');

            expect(initialTokenABalance).to.be.greaterThan(await tokenA_Erc20ForSpl.balanceOf(deployer.address));
            expect(await tokenB_Erc20ForSpl.balanceOf(deployer.address)).to.be.greaterThan(initialTokenBBalance);
        });

        it('swapOutput', async function() {
            const initialTokenABalance = await tokenA_Erc20ForSpl.balanceOf(deployer.address);
            const initialTokenBBalance = await tokenB_Erc20ForSpl.balanceOf(deployer.address);

            const swapOutputAmount = 20000;
            const slippage = 100;

            const poolData = await CallRaydiumCPMMProgram.getPoolData(
                0,
                ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenA)), 32),
                ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenB)), 32),
            );
            console.log(poolData, 'getPoolData');

            const swapInput = await CallRaydiumCPMMProgram.getSwapInput(
                poolId,
                poolData[0],
                ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenA)), 32),
                ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58(tokenB)), 32),
                swapOutputAmount
            );
            console.log(swapInput, 'swapInput');
            
            let tx = await CallRaydiumCPMMProgram.connect(deployer).swapOutput(
                poolId,
                tokenA_Erc20ForSpl.target,
                tokenB_Erc20ForSpl.target,
                swapOutputAmount,
                parseInt((parseInt(swapInput) * (100 + slippage)) / 100),
                slippage  // slippage 1%
            );
            await tx.wait(RECEIPTS_COUNT);
            console.log(tx, 'tx swapOutput');

            expect(initialTokenABalance).to.be.greaterThan(await tokenA_Erc20ForSpl.balanceOf(deployer.address));
            expect(await tokenB_Erc20ForSpl.balanceOf(deployer.address)).to.be.greaterThan(initialTokenBBalance);
        });

        it('collectFees', async function() {
            const initialTokenABalance = await tokenA_Erc20ForSpl.balanceOf(deployer.address);
            const initialTokenBBalance = await tokenB_Erc20ForSpl.balanceOf(deployer.address);
            
            let tx = await CallRaydiumCPMMProgram.connect(deployer).collectFees(
                poolId,
                tokenA_Erc20ForSpl.target,
                tokenB_Erc20ForSpl.target,
                '18446744073709551615', // withdraw maximum available fees
                ethers.zeroPadValue(ethers.toBeHex(deployer.address), 32) // salt
            );
            await tx.wait(RECEIPTS_COUNT);
            console.log(tx, 'tx collectFees');

            expect(await tokenA_Erc20ForSpl.balanceOf(deployer.address)).to.be.greaterThan(initialTokenABalance);
            expect(await tokenB_Erc20ForSpl.balanceOf(deployer.address)).to.be.greaterThan(initialTokenBBalance);
        });
    });
});
