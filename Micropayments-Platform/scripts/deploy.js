const hre = require("hardhat");

async function main() {
  console.log("Deploying Micro-Payments Platform...");

  // Get the ContractFactory and Signers
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Deploy the contract
  const Project = await hre.ethers.getContractFactory("Project");
  const project = await Project.deploy();

  await project.deployed();

  console.log("Micro-Payments Platform deployed to:", project.address);
  console.log("Transaction hash:", project.deployTransaction.hash);

  // Verify deployment
  console.log("Verifying deployment...");
  const owner = await project.owner();
  console.log("Contract owner:", owner);
  console.log("Platform fee:", await project.platformFeePercentage());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });