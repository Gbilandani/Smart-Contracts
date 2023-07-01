// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract MyHomeNft is ERC721, ERC721URIStorage, Ownable, ERC721Holder {
    using Counters for Counters.Counter;
    // address saleContract;

    Counters.Counter private _homeIdCounter;

    constructor() ERC721("Home", "FGH") {}

    // constructor(address _saleContract) ERC721("Home", "FGH") {
    //     saleContract = _saleContract;
    // }

    struct home {
        address owner;
        address seller;
        uint256 hid;
        string image;
        // string houseAddr;
        // string location;
        // string city;
        // string locationType; // beach, mountain, city, vilage (select bar)
        uint256 price;
        bool ForSale;
    }

    mapping(uint256 => home) public hMap;

    // mapping(uint256 => home) public hForSale;
    event PropertyForSale(
        uint256 hid,
        address seller,
        string uri,
        // string location,
        uint256 price,
        uint256 time
    );
    event PropertySold(
        uint256 hid,
        address buyer,
        address seller,
        string uri,
        // string location,
        uint256 price,
        uint256 time
    );

    function Sale(
        string memory _image,
        // string memory _houseAddr,
        // string memory _location,
        // string memory _city,
        // string memory _locationType,
        uint256 _price
    ) public {
        _homeIdCounter.increment();
        uint256 homeId = _homeIdCounter.current();
        _safeMint(address(this), homeId);
        _setTokenURI(homeId, _image);
        hMap[homeId] = home(
            address(this),
            msg.sender,
            homeId,
            _image,
            // _houseAddr,
            // _location,
            // _city,
            // _locationType,
            _price,
            true
        );
        emit PropertyForSale(
            homeId,
            msg.sender,
            hMap[homeId].image,
            // hMap[homeId].location,
            hMap[homeId].price,
            block.timestamp
        );
    }

    modifier checkPrice(uint256 hid) {
        require(hMap[hid].price <= msg.value, "Enter Correct Amount.");
        _;
    }

    modifier checkSale(uint256 hid) {
        require(hMap[hid].ForSale, "This House is NOT FOR SALE...");
        _;
    }

    modifier checkSeller(uint256 hid) {
        require(
            hMap[hid].seller != msg.sender,
            "You are the seller of the property, You can't buy it."
        );
        _;
    }

    function Buy(uint256 hid)
        public
        payable
        checkSale(hid)
        checkSeller(hid)
        checkPrice(hid)
    {
        ERC721(address(this)).approve(msg.sender, hid);
        address sellrr = hMap[hid].seller;
        transferFrom(address(this), msg.sender, hid);
        payable(hMap[hid].seller).transfer(msg.value);
        hMap[hid].owner = msg.sender;
        hMap[hid].seller = address(0);
        hMap[hid].ForSale = false;
        emit PropertySold(
            hid,
            msg.sender,
            sellrr,
            hMap[hid].image,
            // hMap[hid].location,
            msg.value,
            block.timestamp
        );
    }

    function NumberOfProperty() public view returns(uint256){
        return _homeIdCounter.current();
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
