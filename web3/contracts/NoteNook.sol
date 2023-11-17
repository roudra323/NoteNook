// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CSEToken
 * @dev ERC20 token with additional functionality and ownership management.
 */
contract CSEToken is ERC20, Ownable {
    /**
     * @dev Structure to store information about tokens.
     */
    struct TokenInfo {
        uint amount;
        bool isMintedIni;
    }

    /**
     * @dev Structure to store information about members.
     */
    struct MemberInfo {
        string name;
        uint totalTokens;
    }

    mapping(address => TokenInfo) accountToken;
    mapping(address => MemberInfo) memberInfo;

    address[] allMembers;

    /**
     * @dev Contract constructor.
     */
    constructor() ERC20("CSEToken", "CSETK") Ownable(msg.sender) {}

    /**
     * @dev Registers a member with the specified name.
     * @param _name The name of the member.
     */
    function register(string memory _name) public {
        require(!isRegistered(), "You are already registered");
        allMembers.push(msg.sender);
        _mint(msg.sender, 50);
        memberInfo[msg.sender] = MemberInfo(_name, balanceOf(msg.sender));
        accountToken[msg.sender] = TokenInfo(balanceOf(msg.sender), true);
    }

    /**
     * @dev Buys tokens by sending Ether to the contract.
     * @param _amount The amount of tokens to buy.
     */
    function buyToken(uint _amount) public payable {
        require(isRegistered(), "You are not registered!");
        require(
            accountToken[msg.sender].isMintedIni == true,
            "You can mint 50 Tokens for free initially."
        );
        uint amount = 100 * _amount;
        require(msg.value == amount, "Set the correct value");
        (bool sent, ) = owner().call{value: amount}("");
        require(sent, "Failed to send Ether");
        _mint(msg.sender, _amount);
    }

    /**
     * @dev Checks if the caller is registered as a member.
     * @return A boolean indicating whether the caller is registered or not.
     */
    function isRegistered() public view returns (bool) {
        return bytes(memberInfo[msg.sender].name).length > 0;
    }
}

/**
 * @title MarketPlace
 * @dev Marketplace functionality using the CSEToken.
 */
contract MarketPlace is CSEToken {
    uint private noteID;

    /**
     * @dev Structure to store information about a note.
     */
    struct Note {
        uint id;
        string name;
        string description;
        string uri;
        uint price;
        uint time;
        string category;
        address creator;
        address owner;
        bool isApproved;
        bool onStack;
    }

    struct Voting {
        uint upvoting;
        uint downvoting;
        address[] voter;
    }

    Note[] allNotes;
    Note[] listedNotes;
    Note[] approvedNotes;

    mapping(uint => Note) Notes;
    mapping(address => uint) stackedInfo;
    mapping(uint => Voting) votingInfo;
    mapping(uint => address[]) noteOwners;
    mapping(uint => bool) isApproved;
    mapping(address => mapping(uint => bool)) hasVoted;

    /**
     * @dev Modifier to check authorization and valid note ID.
     * @param _id The ID of the note to check.
     */
    modifier checkAuth(uint _id) {
        require(isRegistered(), "You are not registered!");
        require(!Notes[_id].isApproved, "Note is already listed");
        require(_id < noteID, "Invalid note");
        require(!hasVoted[msg.sender][_id], "You can't vote twice");
        _;
    }

    /**
     * @dev Adds a new note to the marketplace.
     * @param _name The name of the note.
     * @param _desc The description of the note.
     * @param _uri The URI of the note.
     * @param _price The price of the note.
     * @param _category The category of the note.
     */
    function addNotes(
        string memory _name,
        string memory _desc,
        string memory _uri,
        uint _price,
        string memory _category
    ) public payable {
        require(msg.sender != owner(), "Owner can't add notes.");
        uint stackingAmount = (_price * 50) / 100;
        transfer(owner(), stackingAmount);

        stackedInfo[msg.sender] = stackingAmount;
        Note memory note = Note(
            noteID,
            _name,
            _desc,
            _uri,
            _price,
            block.timestamp,
            _category,
            msg.sender,
            msg.sender,
            false,
            true
        );
        Notes[noteID] = note;
        noteOwners[noteID].push(msg.sender);
        listedNotes.push(note);
        noteID++;
    }

    /**
     * @dev Retrieves information about a specific note.
     * @param _id The ID of the note to retrieve information about.
     * @return The information about the specified note.
     */
    function getNoteInfo(uint _id) external view returns (Note memory) {
        return Notes[_id];
    }

    /**
     * @dev Retrieves information about a Listed specific note.
     * @return The information about the array specified listed note.
     */
    function getListedNoteInfo() external view returns (Note[] memory) {
        return listedNotes;
    }

    /**
     * @dev Retrieves array about approved notes.
     * @return The information about all approved notes.
     */
    function getApprovedNotes() external view returns (Note[] memory) {
        return approvedNotes;
    }

    // function getVotingInfo(uint _id) external view returns(Voting memory) {
    //     return votingInfo[_id];
    // }

    // function getApprovedorNot(uint _id) external view returns(bool) {
    //     return isApproved[_id];
    // }

    // function getTimesStamp() external view returns(uint) {
    //     return block.timestamp;
    // }

    // function getLength() external view returns(uint) {
    //     return listedNotes.length;
    // }

    /**
     * @dev Records an upvote for a specific note.
     * @param _id The ID of the note to upvote.
     */
    function upVote(uint _id) external checkAuth(_id) {
        hasVoted[msg.sender][_id] = true;
        Voting storage voting = votingInfo[_id];
        voting.voter.push(msg.sender);
        voting.upvoting++;
    }

    /**
     * @dev Records a downvote for a specific note.
     * @param _id The ID of the note to downvote.
     */
    function downVote(uint _id) external checkAuth(_id) {
        hasVoted[msg.sender][_id] = true;
        Voting storage voting = votingInfo[_id];
        voting.voter.push(msg.sender);
        voting.downvoting++;
    }

    /**
     * @dev Checks the voting results for all listed notes and approves notes that meet the criteria.
     */
    function checkResult() public payable onlyOwner {
        for (uint i = 0; i < listedNotes.length; i++) {
            if (
                (isApproved[i] == false) &&
                (Notes[i].time + 5 <= block.timestamp) &&
                (votingInfo[i].upvoting > votingInfo[i].downvoting)
            ) {
                isApproved[i] = true;
                Notes[i].isApproved = true;
                Notes[i].onStack = false;
                approvedNotes.push(Notes[i]);
                uint returnedAmount = stackedInfo[Notes[i].owner];
                stackedInfo[Notes[i].owner] = 0;
                transfer(Notes[i].owner, returnedAmount);
            }
        }
    }

    /**
     * @dev Buys a specific note.
     * @param _id The ID of the note to buy.
     */
    function buyNote(uint _id) public {
        require(isRegistered(), "You are not registered!");
        require(Notes[_id].isApproved, "Note isn't Approved");
        require(_id < noteID, "Invalid note");
        transfer(Notes[_id].owner, Notes[_id].price);
        Notes[_id].owner = msg.sender;
        noteOwners[_id].push(msg.sender);
    }
}