require("ethers");

async function main() {
  const [deployer] = await ethers.getSigners();
  const contract = await ethers.deployContract("NoteNook");

  await contract.waitForDeployment();
  console.log("Contract Deployer:", deployer.address);
  console.log("Contract address:", await contract.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
