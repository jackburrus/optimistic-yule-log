pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';

import './HexStrings.sol';
import './Buzz.sol';

contract YuleLog is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using HexStrings for uint160;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  bool public isBurned;

  uint256 public immutable limit;
  uint256 public immutable curve;
  uint256 public price;
  uint256 public logRegistryCount;

  uint256 public sipsPerForty = 13;
  mapping(uint256 => uint256) public sips;
  mapping(uint256 => bool) public wrapped;
  mapping(uint256 => uint256) public burnTime;

  event Receive(address indexed sender, uint256 indexed amount, uint256 indexed tokenId);

  constructor(
    uint256 _limit,
    uint256 _curve,
    uint256 _price
  ) ERC721('YuleLogs', 'LOG') {
    limit = _limit;
    curve = _curve;
    price = _price;
  }

  function getAll() public view returns (uint256[] memory) {
    uint256[] memory ret = new uint256[](logRegistryCount);
    for (uint256 i = 0; i < logRegistryCount; i++) {
      ret[i] = burnTime[i];
    }
    return ret;
  }

  function numberMinted() public view returns (uint256) {
    return _tokenIds.current();
  }

  function startBurnTime(uint256 id) public {
    require(id > 0, 'id must be greater than 0');
    require(ownerOf(id) == msg.sender, 'only owner can start a burn!');
    require(burnTime[id] == 0, 'id is already burning!');
    // require(!isBurned(id), 'token is already burned');
    // require(id < _tokenIds.get(), "id must be less than total token count");
    // require(!isBurned(id), 'token is already burned');
    burnTime[id] = block.timestamp;
  }

  function getBurnTime(uint256 id) public view returns (uint256) {
    return burnTime[id];
  }

  function mintLog() public payable returns (uint256) {
    require(_tokenIds.current() < limit, 'DONE MINTING');
    require(msg.value >= price, 'NOT ENOUGH');

    price = (price * curve) / 1000;
    logRegistryCount = _tokenIds.current() + 1;
    _tokenIds.increment();

    uint256 id = _tokenIds.current();
    burnTime[id] = 0;
    _mint(msg.sender, id);

    emit Receive(msg.sender, msg.value, id);

    return id;
  }

  function sip(uint256 id) public {
    require(ownerOf(id) == msg.sender, 'only owner can sip!');
    require(sips[id] < sipsPerForty, 'this drink is done!');
    sips[id] += 1;
  }

  function getDays(uint256 id) public view returns (uint256) {
    uint256 existingBurnTime = getBurnTime(id);
    uint256 currentTimestamp = getCurrentTimestamp();
    uint256 diff = (currentTimestamp - existingBurnTime) / 60;

    return diff;
  }

  function getCurrentTimestamp() public view returns (uint256) {
    return block.timestamp;
  }

  function getMapping(uint256 id) public view returns (uint256) {
    return burnTime[id];
  }

  receive() external payable {
    require(_tokenIds.current() < limit, 'no bottles left!');
    emit Receive(msg.sender, msg.value, 0);
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_exists(id), 'not exist');
    string memory name = string(abi.encodePacked('LOG #', id.toString()));
    string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"',
                name,
                '", "description":"',
                ownerOf(id) == address(this) ? 'A recycled bottle of OE' : 'Sipping on cool, crisp OE 40s!',
                '", "external_url":"https://oe40.me", "attributes": ',
                getAttributesForToken(id),
                '"owner":"',
                (uint160(ownerOf(id))).toHexString(20),
                '", "image": "',
                'data:image/svg+xml;base64,',
                image,
                '"}'
              )
            )
          )
        )
      );
  }

  function getAttributesForToken(uint256 id) internal view returns (string memory) {
    return
      string(
        abi.encodePacked(
          '[{"trait_type": "sips", "value": ',
          uint2str(sips[id]),
          '}, {"trait_type": "wrapped", "value": "',
          wrapped[id] ? 'wrapped' : 'unwrapped',
          '"}, {"trait_type": "state", "value": "',
          ownerOf(id) == address(this) ? 'recycled' : 'still OE',
          '"}],'
        )
      );
  }

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {
    string memory svg = string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" width="240" height="300">', renderTokenById(id), '</svg>'));

    return svg;
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    uint256 existingBurnTime = getBurnTime(id);
    uint256 currentTimestamp = getCurrentTimestamp();
    uint256 diff = (currentTimestamp - existingBurnTime) / 60;
    // uint256 diff = (block.timestamp - existingBurnTime) / 60 / 60 / 24;
    string memory log = string(
      abi.encodePacked(
        '<svg width="226" height="104" viewBox="0 0 226 104" fill="none" xmlns="http://www.w3.org/2000/svg">'
        '<path d="M181 3H52V101.5H181C198.5 101.5 221.7 86 222.5 54C223.3 22 200.5 3 181 3Z" fill="#7E5C3F" stroke="#423738" stroke-width="5"/>'
        '<circle cx="50.5" cy="51.5" r="43.5" fill="#EBCAB3"/>'
        '<circle cx="51.5" cy="52.5" r="48" stroke="#413537" stroke-width="7"/>'
        '<circle cx="51" cy="53" r="41.5" stroke="#C69E7E" stroke-width="7"/>'
        '<path d="M113 40H161.5" stroke="#423738" stroke-width="7" stroke-linecap="round"/>'
        '<path d="M152 77H206" stroke="#423738" stroke-width="7" stroke-linecap="round"/>'
        '<path d="M176 40H201" stroke="#423738" stroke-width="7" stroke-linecap="round"/>'
        '<path d="M124 77H141" stroke="#423738" stroke-width="7" stroke-linecap="round"/>'
        '</svg>'
      )
    );

    if (burnTime[id] > 0) {
      log = '<svg width="242" height="271" viewBox="0 0 242 271" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M175.417 126.619L50.763 159.819L76.1138 255.001L200.768 221.801C217.679 217.297 236.108 196.348 228.645 165.22C221.182 134.092 194.261 121.6 175.417 126.619Z" fill="#583E28" stroke="#423738" stroke-width="5"/>'
      '<circle cx="61.796" cy="207.072" r="43.5" transform="rotate(-14.914 61.796 207.072)" fill="#D7B39B"/>'
      '<circle cx="63.0196" cy="207.78" r="48" transform="rotate(-14.914 63.0196 207.78)" stroke="#413537" stroke-width="7"/>'
      '<circle cx="62.6652" cy="208.392" r="41.5" transform="rotate(-14.914 62.6652 208.392)" stroke="#9D7759" stroke-width="7"/>'
      '<path d="M119.231 179.873L166.097 167.391" stroke="#2D2728" stroke-width="7" stroke-linecap="round"/>'
      '<path d="M166.44 205.59L218.621 191.692" stroke="#2D2728" stroke-width="7" stroke-linecap="round"/>'
      '<path d="M180.109 163.659L204.266 157.225" stroke="#2D2728" stroke-width="7" stroke-linecap="round"/>'
      '<path d="M139.383 212.796L155.81 208.421" stroke="#2D2728" stroke-width="7" stroke-linecap="round"/>'
      '<path d="M67.1612 120.865C67.1612 149.5 110.584 161.5 131.063 161.5C148.201 161.5 177.797 149.632 188.563 144C199.33 138.368 197.599 85.5121 195.063 64C194.063 59.8874 188.181 86.3258 182.563 76C176.946 65.6742 172.651 39.8952 169.556 29.3405C167.261 21.5131 152.237 46.472 153.173 42.2478C154.343 36.9675 137.96 0.592434 132.694 0.00573936C128.481 -0.463616 116.116 27.9715 110.46 42.2478C108.835 46.3489 96.2176 24.3578 95.2467 29.3405C93.0756 40.4819 88.5245 61.1371 83.0635 76C76.0421 71.8931 65.5753 56.4338 67.1612 67C68.1767 73.7658 67.1612 90.3063 67.1612 120.865Z" fill="#FA5057"/>'
      '<path d="M71.1245 123.263C72.4423 146.135 111.758 159 130.977 159C147.06 159 174.137 148.334 184.24 143.056C194.344 137.778 193.368 96.14 190.989 75.9809C190.05 72.1269 187.475 95.5482 182.203 85.8718C176.932 76.1954 170.123 47.3861 167.218 37.4952C165.064 30.1601 150.965 53.5492 151.843 49.5907C152.941 44.6425 137.566 10.5552 132.624 10.0054C128.671 9.56554 117.066 36.2123 111.758 49.5907C110.234 53.4339 98.3928 32.8259 97.4816 37.4952C95.4441 47.9359 90.5263 70.2996 85.4013 84.2278C78.812 80.3792 69.6361 66.0792 71.1245 75.9809C72.0775 82.3211 69.4771 94.6739 71.1245 123.263Z" fill="#F89C05"/>'
      '<path d="M76.0743 126.005C77.2743 146.805 113.074 158.505 130.574 158.505C145.219 158.505 169.874 148.805 179.074 144.005C188.274 139.205 191.23 108.838 189.063 90.5049C188.208 87 182.019 100.8 177.219 92C172.419 83.2 166.219 57 163.574 48.0049C161.613 41.3342 148.774 62.6049 149.574 59.0049C150.574 54.5049 136.574 23.5049 132.074 23.0049C128.474 22.6049 117.908 46.8382 113.074 59.0049C111.686 62.5 100.904 43.7585 100.074 48.0049C98.2191 57.5 93.741 77.8382 89.0743 90.5049C83.0743 87.0049 74.7191 74 76.0743 83.0049C76.9421 88.7709 74.5743 100.005 76.0743 126.005Z" fill="#FDD017"/>'
      '</svg>';
    }

    if (diff >= 1 && diff <= 5) {
      log = '<svg width="242" height="298" viewBox="0 0 242 298" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M175.417 153.619L50.7631 186.819L76.1139 282.001L200.768 248.801C217.679 244.297 236.108 223.348 228.645 192.22C221.183 161.092 194.261 148.6 175.417 153.619Z" fill="#482E18" stroke="#423738" stroke-width="5"/>'
      '<circle cx="61.796" cy="234.072" r="43.5" transform="rotate(-14.914 61.796 234.072)" fill="#9A7C69"/>'
      '<circle cx="63.0196" cy="234.78" r="48" transform="rotate(-14.914 63.0196 234.78)" stroke="#413537" stroke-width="7"/>'
      '<circle cx="62.6652" cy="235.392" r="41.5" transform="rotate(-14.914 62.6652 235.392)" stroke="#835B3B" stroke-width="7"/>'
      '<path d="M119.231 206.873L166.097 194.391" stroke="#262525" stroke-width="7" stroke-linecap="round"/>'
      '<path d="M166.44 232.59L218.621 218.692" stroke="#262525" stroke-width="7" stroke-linecap="round"/>'
      '<path d="M180.109 190.659L204.266 184.225" stroke="#262525" stroke-width="7" stroke-linecap="round"/>'
      '<path d="M139.383 239.796L155.81 235.421" stroke="#262525" stroke-width="7" stroke-linecap="round"/>'
      '<path d="M39.2152 161.308C39.2152 199.525 97.1686 215.541 124.5 215.541C147.373 215.541 186.872 199.702 201.241 192.185C215.609 184.668 213.3 114.126 209.916 85.4155C208.58 79.9267 200.73 115.212 193.233 101.431C185.736 87.6498 180.004 53.2448 175.873 39.1583C172.81 28.7118 152.758 62.0222 154.008 56.3846C155.57 49.3374 133.704 0.790672 126.676 0.00765985C121.054 -0.61875 104.551 37.3312 97.002 56.3846C94.8335 61.858 77.9944 32.5084 76.6985 39.1583C73.801 54.0279 67.727 81.5945 60.4386 101.431C51.0677 95.9498 37.0986 75.3174 39.2152 89.4193C40.5705 98.449 39.2152 120.524 39.2152 161.308Z" fill="#FA5057"/>'
      '<path d="M44.5046 164.509C46.2634 195.034 98.7353 212.204 124.385 212.204C145.85 212.204 181.987 197.969 195.471 190.925C208.955 183.881 207.653 128.31 204.478 101.405C203.224 96.2617 199.787 127.52 192.752 114.606C185.717 101.692 176.629 63.2423 172.753 50.0417C169.878 40.2522 151.061 71.4676 152.233 66.1845C153.699 59.5806 133.179 14.0871 126.583 13.3533C121.307 12.7663 105.819 48.3295 98.7353 66.1845C96.7002 71.3137 80.8973 43.81 79.6812 50.0417C76.962 63.976 70.3985 93.8231 63.5586 112.412C54.7644 107.275 42.5182 88.1903 44.5046 101.405C45.7765 109.867 42.306 126.353 44.5046 164.509Z" fill="#F89C05"/>'
      '<path d="M51.1107 168.168C52.7122 195.928 100.492 211.543 123.847 211.543C143.393 211.543 176.298 198.597 188.576 192.191C200.855 185.785 204.8 145.257 201.908 120.789C200.767 116.112 192.506 134.529 186.1 122.785C179.694 111.04 171.419 76.0731 167.89 64.0681C165.272 55.1653 148.137 83.5535 149.205 78.7489C150.54 72.7431 131.855 31.37 125.849 30.7027C121.045 30.1688 106.942 62.5111 100.492 78.7489C98.6384 83.4135 84.2488 58.4008 83.1415 64.0681C80.6655 76.7404 74.6889 103.884 68.4607 120.789C60.453 116.118 49.302 98.7616 51.1107 110.78C52.2689 118.475 49.1088 133.468 51.1107 168.168Z" fill="#FDD017"/>'
      '</svg>';
    } else if (diff > 5 && diff < 500) {
      log = '<svg width="242" height="150" viewBox="0 0 242 157" fill="none" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M175.417 12.6187L50.7631 45.8193L76.1139 141.001L200.768 107.801C217.679 103.297 236.108 82.3478 228.645 51.2199C221.183 20.092 194.261 7.60003 175.417 12.6187Z" fill="#2D1909" stroke="#423738" stroke-width="5"/>'
      '<circle cx="61.796" cy="93.0715" r="43.5" transform="rotate(-14.914 61.796 93.0715)" fill="#3A2E26"/>'
      '<circle cx="63.0196" cy="93.7805" r="48" transform="rotate(-14.914 63.0196 93.7805)" stroke="#413537" stroke-width="7"/>'
      '<circle cx="62.6652" cy="94.3923" r="41.5" transform="rotate(-14.914 62.6652 94.3923)" stroke="#43403D" stroke-width="7"/>'
      '<path d="M119.231 65.8734L166.097 53.391" stroke="#3C3737" stroke-width="7" stroke-linecap="round"/>'
      '<path d="M166.44 91.5896L218.621 77.6917" stroke="#3C3737" stroke-width="7" stroke-linecap="round"/>'
      '<path d="M180.109 49.6591L204.266 43.2249" stroke="#3C3737" stroke-width="7" stroke-linecap="round"/>'
      '<path d="M139.383 98.7959L155.81 94.4206" stroke="#3C3737" stroke-width="7" stroke-linecap="round"/>'
      '</svg>';
    }

    string memory render = string(abi.encodePacked(log));

    return render;
  }

  function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return '0';
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }
}
