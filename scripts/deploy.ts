/* eslint-disable camelcase */
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from "hardhat";

import { Certificate__factory, Certification__factory, Course__factory } from "../src/types/factories/contracts";

async function main() {
  const accounts = await ethers.getSigners();

  console.log("Deploying contracts with the account:", accounts[0].address);

  const courseFactory = <Course__factory>await ethers.getContractFactory("Course");
  const course = await courseFactory.deploy();

  await course.deployed();
  console.log("Course deployed to:", course.address);

  const certificateFactory = <Certificate__factory>await ethers.getContractFactory("Certificate");
  const certificate = await certificateFactory.deploy();

  await certificate.deployed();
  console.log("Certificate deployed to:", certificate.address);

  const certificationFactory = <Certification__factory>await ethers.getContractFactory("Certification");
  const certification = await certificationFactory.deploy(course.address, certificate.address);

  await certification.deployed();
  console.log("Certification deployed to:", certification.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
