// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

import "./Course.sol";
import "./Certificate.sol";

contract Certification is ERC721, ERC721Enumerable, ERC721URIStorage, ChainlinkClient, ConfirmedOwner {
    using Counters for Counters.Counter;
    using Chainlink for Chainlink.Request;

    Counters.Counter private _tokenIdCounter;

    struct CertificationData {
        uint256 courseID;
        uint256 certificateID;
    }

    bytes32 private jobId;
    uint256 private fee;

    event RequestVerification(bytes32 indexed requestId, bool verification);

    // certifications emitted by user
    mapping(address => uint256[]) public certifications;

    mapping(uint256 => CertificationData) public certificationData;

    Course public courseAddress;
    Certificate public certificateAddress;

    mapping(address => mapping(uint256 => mapping(uint256 => bool))) private isAuthorized;
    uint256 public priceToAuthorize;

    constructor(
        address _courseAddress,
        address _certificateAddress,
        uint256 price
    ) ERC721("Certification", "CERTIFICATION") ConfirmedOwner(msg.sender) {
        courseAddress = Course(_courseAddress);
        certificateAddress = Certificate(_certificateAddress);

        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0x40193c8518BB267228Fc409a613bDbD8eC5a97b3);
        jobId = "ca98366cc7314957b8c012c72f05aeeb";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)

        priceToAuthorize = price;
    }

    function requestCourseCompletionVerification(address user, uint256 courseId) public returns (bytes32 requestId) {
        // Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        // // Set the URL to perform the GET request on
        // // req.add(
        // //     "get",
        // //     string(abi.encodePacked("https://educa.dao/data/courseCompletion/", string(user), "/", string(courseId)))
        // // );
        // req.add("get", string(abi.encodePacked("https://educa.dao/data/courseCompletion/")));
        // req.add("path", "data,validation"); // Chainlink nodes 1.0.0 and later support this format
        // // Sends the request
        // return sendChainlinkRequest(req, fee);
        return 0x000;
    }

    /**
     * Receive the response in the form of bool
     */
    function fulfill(bytes32 _requestId, bool verification)
        public
        returns (
            // recordChainlinkFulfillment(_requestId)
            bool
        )
    {
        emit RequestVerification(_requestId, verification);
        return true;
    }

    function verifyCourseCompletion(address user, uint256 courseId) public returns (bool) {
        bytes32 requestId = requestCourseCompletionVerification(user, courseId);

        return fulfill(requestId, true);
    }

    function safeMint(
        address to,
        string memory uri,
        uint256 certificateID
    ) external payable {
        require(verifyCourseCompletion(to, certificateID), "User has not completed the course");

        uint256 tokenId = _tokenIdCounter.current();
        certifications[to].push(tokenId);
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        (uint256 courseID, uint256 price) = certificateAddress.getCertificateData(certificateID);

        certificationData[tokenId] = CertificationData(courseID, certificateID);

        require(msg.value == price, "Price mismatch!");

        address certificateProducer = certificateAddress.producers(certificateID);
        address courseProducer = courseAddress.producers(courseID);

        uint256 value = msg.value / 2;
        (bool sent, bytes memory data) = certificateProducer.call{ value: value }("");
        require(sent, "Failed to pay certificate producer");

        (sent, data) = courseProducer.call{ value: value }("");
        require(sent, "Failed to pay course producer");
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function authorize(uint256 courseID, uint256 certificateID) external payable {
        require(msg.value == priceToAuthorize, "Price mismatch!");
        isAuthorized[msg.sender][courseID][certificateID] = true;

        address certificateProducer = certificateAddress.producers(certificateID);
        address courseProducer = courseAddress.producers(courseID);

        uint256 value = msg.value / 2;
        (bool sent, bytes memory data) = certificateProducer.call{ value: value }("");
        require(sent, "Failed to pay certificate producer");

        (sent, data) = courseProducer.call{ value: value }("");
        require(sent, "Failed to pay course producer");
    }

    function _isAuthorizedOrOwner(address account, uint256 tokenId) internal view returns (bool) {
        CertificationData memory data = certificationData[tokenId];

        return ownerOf(tokenId) == account || isAuthorized[account][data.courseID][data.certificateID];
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_isAuthorizedOrOwner(msg.sender, tokenId), "Not authorized!");

        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
