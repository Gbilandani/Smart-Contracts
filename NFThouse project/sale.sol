// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract sale is ERC721Holder{
    using Counters for Counters.Counter;
    Counters.Counter private _homeIdCounter;

    struct home {
        address owner;
        address seller;
        uint256 hid;
        string image;
        string location;
        uint256 price;
        bool ForSale;
    }

    mapping(uint256 => home) public hMapSale;

    function Sale(
        address homecontract,
        address seller,
        uint _hid,
        string memory _image,
        string memory _location,
        uint256 _price
    ) public {
        // _homeIdCounter.increment();
        // uint256 homeId = _homeIdCounter.current();
       
        hMapSale[_hid] = home(
            msg.sender,
            seller,
            _hid,
            _image,
            _location,
            _price,
            true
        );
    }

    modifier checkPrice(uint256 hid) {
        require(hMapSale[hid].price <= msg.value, "Enter Correct Amount.");
        _;
    }

    modifier checkSale(uint256 hid) {
        require(hMapSale[hid].ForSale, "Enter Correct Amount.");
        _;
    }

    function Buy(uint256 hid, address home) public payable checkSale(hid) checkPrice(hid) {
        hMapSale[hid].owner = msg.sender;
        hMapSale[hid].seller = address(0);
        hMapSale[hid].ForSale = false;
        IERC721(home).transferFrom(address(this), msg.sender, hid);
    }
}