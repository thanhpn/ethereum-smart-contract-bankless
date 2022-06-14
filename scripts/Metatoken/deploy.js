const hre = require("hardhat");
const { getImplementationAddress } = require("@openzeppelin/upgrades-core");

async function main() {
    //npx hardhat run scripts/MetaToken/deploy.js --network bsc-testnet
    const MetaToken = await hre.ethers.getContractFactory("MetaToken");
    const tokenContract = await upgrades.deployProxy(MetaToken);
    await tokenContract.deployed();
    console.log("MetaToken deployed to:", tokenContract.address);

    try {
        const implAddress = await getImplementationAddress(
            tokenContract.provider,
            tokenContract.address
        );
        await hre.run("verify:verify", { address: implAddress });
        console.log("MetaToken verified to:", implAddress);
    } catch (e) {

    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
//npx hardhat run scripts/MetaToken/deploy.js --network mainnet