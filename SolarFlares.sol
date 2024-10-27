// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.25;

import "./IJsonApiVerification.sol";
import "./JsonApiVerification.sol";
import "./Base64.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v5.0/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v5.0/contracts/access/Ownable.sol";
import {TestFtsoV2Interface} from "@flarenetwork/flare-periphery-contracts/coston2/TestFtsoV2Interface.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v5.0/contracts/utils/Strings.sol";

    struct SolarFlare {
        string NasaFlareID;
        uint256 beginTime;
        uint256 peakTime;
        uint256 endTime;
        string classType;
        string sourceLocation;
        uint256 activeRegionNum;
        string note;
        string btcprice;
        string flrprice;
        string xrpprice;
    }


contract SolarFlareCollectible is ERC721Enumerable,Ownable{

    TestFtsoV2Interface internal ftsoV2;

    string private _baseURIextended;
    string private _contractURI;
    string private _imageurl;

  	uint private _tokenIdTracker;
    bytes21 private flrID = bytes21(0x01464c522f55534400000000000000000000000000);
    bytes21 private btcID = bytes21(0x014254432f55534400000000000000000000000000);
    bytes21 private xrpID = bytes21(0x015852502f55534400000000000000000000000000);


    SolarFlare[] public flares;

    IJsonApiVerification public jsonApiAttestationVerification;

    mapping(string => bool) private flareExists;

    constructor() ERC721("Solar Flare Collectibles", "SOLARFLARE") Ownable(msg.sender){
        
        ftsoV2 = TestFtsoV2Interface(0x3d893C53D9e8056135C26C8c638B76C8b60Df726);
         _contractURI = "https://example.com/contractmetadata";
         _imageurl = "https://example.com/img/solarimg";

        jsonApiAttestationVerification = new JsonApiVerification();

        //mock first token
        SolarFlare memory mockFlare = SolarFlare({
            NasaFlareID: "2016-01-01T23:00:00-FLR-001",
            beginTime: 1451692800, // Timestamp for "2016-01-01T23:00Z"
            peakTime: 1451697000,  // Timestamp for "2016-01-02T00:10Z"
            endTime: 0,            // Null value represented as 0
            classType: "M2.3",
            sourceLocation: "S21W73",
            activeRegionNum: 12473,
            note: "Associated eruption visible in SOD AIA 171, 193, and 304 with opening field lines and filament liftoff.",
            btcprice: "500000.00", // 500,000 BTC
            flrprice: "7.00",      // 7 FLR
            xrpprice: "589.00"     // 589 XRP
        });

        flareExists[mockFlare.NasaFlareID] = true;
        flares.push(mockFlare);
        
        _mint(msg.sender, _tokenIdTracker);
        _tokenIdTracker += 1;
    }

    //Set and return URIs
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    function setContractURI(string memory contractURI_,string memory imageuri) external onlyOwner{
        _contractURI = contractURI_;
        _imageurl = imageuri;
    }
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    function tokenURI(uint tokenId) public view virtual override returns (string memory) {

        string memory base = _baseURI();
        string memory json = formatTokenURI(tokenId);
        return bytes(base).length > 0 ? string(abi.encodePacked(base, json)) : json;
    }


//ADD Nasa Flare Data from API
    function addSolarFlare(IJsonApi.Response calldata jsonResponse) public {
        // We mock the proof for testing and hackathon
        IJsonApi.Proof memory proof = IJsonApi.Proof({
            merkleProof: new bytes32[](0),
            data: jsonResponse
        });
        require(
            jsonApiAttestationVerification.verifyJsonApi(proof),
            "Invalid proof"
        );

        SolarFlare memory _flare = abi.decode(
            jsonResponse.responseBody.abi_encoded_data,
            (SolarFlare)
        );

        // Check if the NasaFlareID already exists in the mapping
        require(!flareExists[_flare.NasaFlareID], "NASA Flare ID already exists");
        
        // Mark the NasaFlareID as used and then push it to our cool array
        flareExists[_flare.NasaFlareID] = true;
        flares.push(_flare);

        //update current prices
        flares[flares.length-1].flrprice = getPrice(0);
        flares[flares.length-1].btcprice = getPrice(1);
        flares[flares.length-1].xrpprice = getPrice(2);
                
        //actual token minting
        _mint(msg.sender, _tokenIdTracker);
        _tokenIdTracker += 1;

    }

  
    function getPrice(uint8 which) private view returns (string memory) {
        uint256 feedValue;
        int8 decimals;

        if (which == 0) {
            (feedValue, decimals,) = ftsoV2.getFeedById(flrID);
        } else if (which == 1) {
            (feedValue, decimals,) = ftsoV2.getFeedById(btcID);
        } else if (which == 2) {
            (feedValue, decimals,) = ftsoV2.getFeedById(xrpID);
        } else {
            revert("Invalid price ID");
        }

        return formatPriceWithDecimals(feedValue, decimals);
    }



    function formatTokenURI(uint256 _id) private view returns (string memory) {
        SolarFlare memory flare = flares[_id]; // Assuming _flareData is the mapping holding SolarFlare data
        
        // Construct image URL using classType
        string memory imageUrl = string(abi.encodePacked(_imageurl, flare.classType, ".png"));

        // Part 1 of JSON metadata: basic info
        string memory jsonPart1 = string(
            abi.encodePacked('{"name": "Solar Flare #',
                Strings.toString(_id),
                '", "description": "A unique Solar Flare NFT representing data from a real solar flare event.", "image": "',
                imageUrl,
                '", "attributes": ['
            )
        );

        // Part 2 of JSON metadata: attributes based on SolarFlare struct fields
        string memory jsonPart2 = string(
            abi.encodePacked(
                '{"trait_type": "NASA Flare ID", "value": "', flare.NasaFlareID, '"},',
                '{"trait_type": "Begin Time", "value": ', Strings.toString(flare.beginTime), '},',
                '{"trait_type": "Peak Time", "value": ', Strings.toString(flare.peakTime), '},',
                '{"trait_type": "End Time", "value": ', Strings.toString(flare.endTime), '},',
                '{"trait_type": "Class Type", "value": "', flare.classType, '"},',
                '{"trait_type": "Source Location", "value": "', flare.sourceLocation, '"},',
                '{"trait_type": "Active Region Number", "value": ', Strings.toString(flare.activeRegionNum), '},',
                '{"trait_type": "Note", "value": "', flare.note, '"},',
                '{"trait_type": "BTC Price", "value": "', flare.btcprice, '"},',
                '{"trait_type": "FLR Price", "value": "', flare.flrprice, '"},',
                '{"trait_type": "XRP Price", "value": "', flare.xrpprice, '"}',
                ']}'
            )
        );

        string memory json = string(abi.encodePacked(jsonPart1, jsonPart2));
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    
    // Helper function to format price with decimals, accounting for positive and negative decimals
    function formatPriceWithDecimals(uint256 price, int8 decimals) internal pure returns (string memory) {
        if (decimals >= 0) {
            uint256 decimalPlaces = uint256(int256(decimals));
            uint256 integerPart = price / (10 ** decimalPlaces);
            uint256 fractionalPart = price % (10 ** decimalPlaces);
            return string(abi.encodePacked(uintToString(integerPart), ".", fractionalToString(fractionalPart, decimalPlaces)));
        } else {
            uint256 adjustedPrice = price * (10 ** uint256(-int256(decimals)));
            return uintToString(adjustedPrice);
        }
    }

    // Helper function to format fractional part with leading zeros if needed
    function fractionalToString(uint256 fractionalPart, uint256 decimals) internal pure returns (string memory) {
        bytes memory buffer = new bytes(decimals);
        for (uint256 i = decimals; i > 0; i--) {
            buffer[i - 1] = bytes1(uint8(48 + fractionalPart % 10));
            fractionalPart /= 10;
        }
        return string(buffer);
    }

    // Helper function to convert uint256 to string
    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }




    function collectFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

//FIN
}
