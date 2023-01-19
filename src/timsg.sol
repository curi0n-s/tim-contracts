// SPDX-License-Identifier: MIT

// Riffing on Hoots.xyz nftmsg @ 0x0217a10f9508939680fd0E1288d66Dc581021319 to make more gas efficient

pragma solidity >=0.8.0 <0.9.0;

import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "lib/ERC1155D/contracts/ERC1155D.sol";
import "./base64.sol";

contract TIM is ERC1155, ReentrancyGuard, Ownable {
    using Strings for uint256;
    
    bool public paused = false;
    
    mapping(uint256 => Message) public MessagesToTokenId;
    
    string public domain = "timsg.xyz";
    string public description = "";

    string public nft_name = "TemporarilyImmutableMessage";

    string public header = "";
    string public footer = "";

    uint256 public minPrice = 0.00 ether;

    uint256 public totalSupply; //unlimited
    uint256 public totalBurned;
    uint256 public totalMinted;
    
    struct Message {
        string name;
        string description;
        bytes bytesValue;
    }

    struct MessageLines {
        string[12] lines;
    }

    constructor() ERC1155("") {
        header = string(abi.encodePacked(
                        '<svg id="card" viewBox="0 0 200 300" xmlns="http://www.w3.org/2000/svg">',
                        '<rect x="2" y="2" rx="2" ry="2" width="196" height="296" style="fill:white;stroke:black;stroke-width:2;opacity:1"></rect>',
                        '<text style="white-space:pre;fill:rgb(15,12,29);font:normal 16px Courier, Monospace, serif;" x="7" y="17">'));

        footer = string(abi.encodePacked(
            '<rect x="3" y="245" rx="0" ry="0" width="194" height="52" style="fill:rgb(15, 12, 29);stroke-width:0;opacity:0.0;"></rect>',
            '<text style="font:bold 10px Courier, Monospace, serif;fill:rgb(88, 85, 122)" x="7" y="278">',
            domain,
            '</text>'));
      description = string(abi.encodePacked(
        domain,
        ': TIM'
      ));
    }

    function stringToBytes(string memory source) public pure returns (bytes memory) {
        bytes memory result = new bytes(bytes(source).length);
        for (uint i = 0; i < bytes(source).length; i++) {
            result[i] = bytes(source)[i];
        }
        return result;
    }

    function convertStringToBytesUnlimited(string memory source) public pure returns (bytes memory) {
        return bytes(source);
    }

    function convertStringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly { // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }

    function mintTo(bytes memory _userTextLines, uint256 _quantity, address[] memory _to, bool asAirdrop) public payable {
        require(!paused, "Minting is paused.");

        uint256 supply = totalSupply;

        Message memory newMessage = Message(
            string(abi.encodePacked(nft_name,
            ' (#', uint256(supply + 1).toString(), ')')),
            description,
            _userTextLines
        );

        for (uint256 i = 0; i < _quantity; i++) {
            if (msg.sender != owner()) {
                require(Math.mulDiv(msg.value, 1, _quantity) >= minPrice);
            }

            MessagesToTokenId[supply + 1] = newMessage; //Add Message to mapping @tokenId
            if (asAirdrop) { 
                _mint(_to[i], supply+1, 1, "");
            } else {
                _mint(msg.sender, supply+1, 1, "");
                safeTransferFrom(msg.sender, _to[i], supply +1 , 1, "");
            }
            ++totalMinted;
            ++totalSupply;
        }
    }

    function burnMessage(uint256 _tokenId) public {
        require(balanceOf(msg.sender, _tokenId) == 1, "Only owner can burn message.");
        _burn(msg.sender, _tokenId, 1);
        ++totalBurned;
        --totalSupply;
    }

    function getSVGTextLine(uint256 _startingY, string memory _text) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<tspan x="7" y="', 
                Strings.toString(_startingY),
                '">',
                _text,
                '</tspan>'));
    }

    function getTextBlock0(bytes memory _bytesMessage) private pure returns (string memory) {
        MessageLines memory currentMessageLines = abi.decode(_bytesMessage, (MessageLines));
        return string(abi.encodePacked(currentMessageLines.lines[0]));
    }

    function getTextBlock1(uint256 _startingY, bytes memory _bytesMessage) private pure returns (string memory) {
        MessageLines memory currentMessageLines = abi.decode(_bytesMessage, (MessageLines));
        return string(abi.encodePacked(
            getSVGTextLine(_startingY+20, currentMessageLines.lines[1]),
            getSVGTextLine(_startingY+40, currentMessageLines.lines[2]),
            getSVGTextLine(_startingY+60, currentMessageLines.lines[3]),
            getSVGTextLine(_startingY+80, currentMessageLines.lines[4]),
            getSVGTextLine(_startingY+100, currentMessageLines.lines[5])
            ));
    }

    function getTextBlock2(uint256 _startingY, bytes memory _bytesMessage) private pure returns (string memory) {
        MessageLines memory currentMessageLines = abi.decode(_bytesMessage, (MessageLines));
        return string(abi.encodePacked(
            getSVGTextLine(_startingY, currentMessageLines.lines[6]),
            getSVGTextLine(_startingY+20, currentMessageLines.lines[7]),
            getSVGTextLine(_startingY+40, currentMessageLines.lines[8]),
            getSVGTextLine(_startingY+60, currentMessageLines.lines[9]),
            getSVGTextLine(_startingY+80, currentMessageLines.lines[10]),
            getSVGTextLine(_startingY+100, currentMessageLines.lines[11])
            ));
    }

    function buildImage(uint256 _tokenId) private view returns (string memory) {
        Message memory currentMessage = MessagesToTokenId[_tokenId];
        return
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        header,
                        getTextBlock0(currentMessage.bytesValue),
                        getTextBlock1(37, currentMessage.bytesValue),
                        getTextBlock2(157, currentMessage.bytesValue),
                        '</text>',
                        footer,
                        '</svg>'
                    )
                )
            );
    }

    function buildMetadata(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        Message memory currentMessage = MessagesToTokenId[_tokenId];
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                currentMessage.name,
                                '", "external_url": "https://',
                                domain,
                                '", "description":"',
                                currentMessage.description,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                buildImage(_tokenId),
                                '", "attributes": ',
                                "[",
                                '{"trait_type": "TIM-ID",',
                                '"value":"',
                                Strings.toString(_tokenId),
                                '"}',
                                "]",
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function uri(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // require(
        //     _tokenId <= totalSupply
        // );
        return buildMetadata(_tokenId);
    }

    /* only owner... */
    function setPaused(bool _paused) public onlyOwner {
        require(msg.sender == owner(), "You are not the owner");
        paused = _paused;
    }

    function setMetadata(string memory _domain, string memory _name, string memory _description) public onlyOwner {
      require(msg.sender == owner(), "You are not the owner");
        description = _description;
        nft_name = _name;
        domain = _domain;
    }

    function setHeaderFooter(bytes memory _bHeader, bytes memory _bFooter) public onlyOwner {
        require(msg.sender == owner(), "You are not the owner");
        header = abi.decode(_bHeader, (string));
        footer = abi.decode(_bFooter, (string));
    }

    function setMinPrice(uint256 _newPrice) public onlyOwner {
        minPrice = _newPrice;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}