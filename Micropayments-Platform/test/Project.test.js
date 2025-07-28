const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Micro-Payments Platform", function () {
  let project;
  let owner;
  let creator;
  let user;

  beforeEach(async function () {
    [owner, creator, user] = await ethers.getSigners();
    
    const Project = await ethers.getContractFactory("Project");
    project = await Project.deploy();
    await project.deployed();
  });

  describe("Content Registration", function () {
    it("Should register content successfully", async function () {
      const contentId = "test-content-1";
      const price = ethers.utils.parseEther("0.001");

      await project.connect(creator).registerContent(contentId, price);

      const contentInfo = await project.getContentInfo(contentId);
      expect(contentInfo.creator).to.equal(creator.address);
      expect(contentInfo.price).to.equal(price);
    });

    it("Should not allow duplicate content registration", async function () {
      const contentId = "test-content-1";
      const price = ethers.utils.parseEther("0.001");

      await project.connect(creator).registerContent(contentId, price);
      
      await expect(
        project.connect(creator).registerContent(contentId, price)
      ).to.be.revertedWith("Content already exists");
    });
  });

  describe("Payments", function () {
    beforeEach(async function () {
      const contentId = "test-content-1";
      const price = ethers.utils.parseEther("0.001");
      await project.connect(creator).registerContent(contentId, price);
    });

    it("Should process payment successfully", async function () {
      const contentId = "test-content-1";
      const price = ethers.utils.parseEther("0.001");

      await project.connect(user).makePayment(contentId, { value: price });

      expect(await project.checkAccess(user.address, contentId)).to.be.true;
      expect(await project.getBalance(creator.address)).to.be.above(0);
    });

    it("Should not allow duplicate purchases", async function () {
      const contentId = "test-content-1";
      const price = ethers.utils.parseEther("0.001");

      await project.connect(user).makePayment(contentId, { value: price });
      
      await expect(
        project.connect(user).makePayment(contentId, { value: price })
      ).to.be.revertedWith("Already purchased");
    });
  });

  describe("Withdrawals", function () {
    it("Should allow withdrawal of earned funds", async function () {
      const contentId = "test-content-1";
      const price = ethers.utils.parseEther("0.001");

      await project.connect(creator).registerContent(contentId, price);
      await project.connect(user).makePayment(contentId, { value: price });

      const initialBalance = await creator.getBalance();
      await project.connect(creator).withdrawFunds();
      const finalBalance = await creator.getBalance();

      expect(finalBalance).to.be.above(initialBalance);
    });
  });
});