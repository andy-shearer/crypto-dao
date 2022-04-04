const { ethers } = require("hardhat");
const { CRYPTODEVS_NFT_CONTRACT_ADDRESS } = require("../constants");

async function main() {
  // Deploy the mock NFT marketplace
  const marketplaceContract = await ethers.getContractFactory("FakeNFTMarketplace");
  const deployedMarketplaceContract = await marketplaceContract.deploy();

  await deployedMarketplaceContract.deployed();
  console.log("Mock marketplace contract deployed to:", deployedMarketplaceContract.address);


  // Deploy the DAO contract
  const daoContract = await ethers.getContractFactory("CryptoDevsDAO");
  const deployedContract = await daoContract.deploy(deployedMarketplaceContract.address, CRYPTODEVS_NFT_CONTRACT_ADDRESS);

  await deployedContract.deployed();
  console.log("CryptoDevsDAO Contract deployed to:", deployedContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
