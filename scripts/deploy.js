// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Deploy the libraries
  
  const LinkedListLib = await hre.ethers.getContractFactory("LinkedListLib");
  const linkedListLib = await LinkedListLib.deploy();
  await linkedListLib.deployed();
  console.log("LinkedListLib deployed to:", linkedListLib.address);
  
  const OBXReferral = await hre.ethers.getContractFactory("OBXReferral");
  const ObxReferral = await OBXReferral.deploy();
  await ObxReferral.deployed();
  console.log("OBXReferral deployed to:", ObxReferral.address);
   
  // We get the contract to deploy
const Factory = await hre.ethers.getContractFactory("OBXFactory",   
{
  libraries: {
    LinkedListLib: linkedListLib.address
  }
} );

  const factory = await Factory.deploy(ObxReferral.address);
  await factory.deployed();
  console.log("Factory deployed to:", factory.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
