/* eslint-disable camelcase */
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";

import {
  Certificate,
  Certificate__factory,
  Certification,
  Certification__factory,
  Course,
  Course__factory,
} from "../src/types";

describe.only("Unit tests", function () {
  let course: Course;
  let certificate: Certificate;
  let certification: Certification;
  let accounts: SignerWithAddress[];

  before(async function () {
    accounts = await ethers.getSigners();
  });

  beforeEach(async function () {
    const courseFactory = <Course__factory>await ethers.getContractFactory("Course");
    course = await courseFactory.deploy();

    await course.deployed();

    const certificateFactory = <Certificate__factory>await ethers.getContractFactory("Certificate");
    certificate = await certificateFactory.deploy();

    await certificate.deployed();

    const certificationFactory = <Certification__factory>await ethers.getContractFactory("Certification");
    certification = await certificationFactory.deploy(
      course.address,
      certificate.address,
      ethers.utils.parseEther("10"),
    );

    await certification.deployed();
  });

  it("User should be able to mint a new course", async function () {
    await course.safeMint(accounts[0].address, "aaaaaa");

    expect(await course.totalSupply()).to.equals(1);
    expect(await course.balanceOf(accounts[0].address)).to.equals(1);
    expect(await course.ownerOf(0)).to.equals(accounts[0].address);
    expect(await course.producers(0)).to.equals(accounts[0].address);
    expect(await course.courses(accounts[0].address, 0)).to.equals(0);
    expect(await course.tokenURI(0)).to.equals("aaaaaa");
  });

  it("User should be able to mint a certificate for a course", async function () {
    await course.safeMint(accounts[0].address, "aaaaaa");
    await certificate.safeMint(accounts[0].address, "bbbbbb", 0, ethers.utils.parseEther("10"));

    expect(await certificate.totalSupply()).to.equals(1);
    expect(await certificate.balanceOf(accounts[0].address)).to.equals(1);
    expect(await certificate.ownerOf(0)).to.equals(accounts[0].address);
    expect(await certificate.producers(0)).to.equals(accounts[0].address);
    expect(await certificate.certificates(accounts[0].address, 0)).to.equals(0);
    expect((await certificate.getCertificateData(0)).courseID).to.equals(0);
    expect((await certificate.getCertificateData(0)).price).to.equals(ethers.utils.parseEther("10"));
    expect(await certificate.tokenURI(0)).to.equals("bbbbbb");
  });

  it("User should be able to mint a certification for a course", async function () {
    await course.safeMint(accounts[0].address, "aaaaaa");
    await certificate.safeMint(accounts[0].address, "bbbbbb", 0, ethers.utils.parseEther("10"));
    await certification.safeMint(accounts[0].address, "cccccc", 0, { value: ethers.utils.parseEther("10") });

    expect(await certification.totalSupply()).to.equals(1);
    expect(await certification.balanceOf(accounts[0].address)).to.equals(1);
    expect(await certification.ownerOf(0)).to.equals(accounts[0].address);
    expect(await certification.certifications(accounts[0].address, 0)).to.equals(0);
    expect((await certification.certificationData(0)).courseID).to.equals(0);
    expect((await certification.certificationData(0)).certificateID).to.equals(0);
    expect(await certification.tokenURI(0)).to.equals("cccccc");
  });

  it("Should revert when non-authorized user tries to access certification metadata", async function () {
    await course.safeMint(accounts[0].address, "aaaaaa");
    await certificate.safeMint(accounts[0].address, "bbbbbb", 0, ethers.utils.parseEther("10"));
    await certification.safeMint(accounts[0].address, "cccccc", 0, { value: ethers.utils.parseEther("10") });

    await expect(certification.connect(accounts[1]).tokenURI(0)).to.be.revertedWith("Not authorized!");
  });

  it("User should be able to pay to be able to see a token metadata", async function () {
    await course.safeMint(accounts[0].address, "aaaaaa");
    await certificate.safeMint(accounts[0].address, "bbbbbb", 0, ethers.utils.parseEther("10"));
    await certification.safeMint(accounts[0].address, "cccccc", 0, { value: ethers.utils.parseEther("10") });

    await certification.connect(accounts[1]).authorize(0, 0, { value: ethers.utils.parseEther("10") });

    expect(await certification.connect(accounts[1]).tokenURI(0)).to.equals("cccccc");
  });
});
