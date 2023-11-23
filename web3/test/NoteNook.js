const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NoteNook", function () {
  let contract;
  let owner;
  let addr1;
  let addr2;
  let addr3;
  let addr4;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
    contract = await ethers.deployContract("NoteNook");
    await contract.waitForDeployment();
  });

  describe("Basic", function () {
    it("Should return the right owner", async function () {
      expect(await contract.owner()).to.equal(owner.address);
    });

    it("should return the owner native token balance", async function () {
      expect(await contract.balanceOf(owner)).to.equal(0);
    });

    it("should return true if a user is registered", async function () {
      expect(await contract.connect(addr1).isRegistered()).to.equal(false);
    });

    it("should register a user", async function () {
      await contract.connect(addr1).register("Asir");
      expect(await contract.connect(addr1).isRegistered()).to.equal(true);
    });
  });
});
