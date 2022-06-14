const hre = require("hardhat");

//npx hardhat verify --network bsc-testnet 
async function main() {
    const MetaToken = await hre.ethers.getContractFactory("MetaToken");
    const contractAddress = "";

    console.log("Upgrading BaseMStationNFT...");
    const contractUpgrade = await upgrades.upgradeProxy(contractAddress, MetaToken);
    await contractUpgrade.deployed();

    console.log("contractUpgrade upgraded");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
//npx hardhat run scripts/MetaToken/upgrade.js --network mainnet