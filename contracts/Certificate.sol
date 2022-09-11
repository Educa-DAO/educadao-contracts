// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Certificate is ERC721, ERC721Enumerable, ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    struct CertificateData {
        uint256 courseID;
        uint256 price;
    }

    address[] public producers;

    // certificate produced by certificate producer
    mapping(address => uint256[]) public certificates;

    mapping(uint256 => CertificateData) public certificateData;

    constructor() ERC721("Certificate", "CERTIFICATE") {}

    function safeMint(
        address to,
        string memory uri,
        uint256 courseID,
        uint256 price
    ) external {
        uint256 tokenId = _tokenIdCounter.current();
        producers.push(to);
        certificates[to].push(tokenId);
        certificateData[tokenId] = CertificateData(courseID, price);
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function getCertificateData(uint256 id) public view returns (uint256 courseID, uint256 price) {
        CertificateData memory data = certificateData[id];

        return (data.courseID, data.price);
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

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
