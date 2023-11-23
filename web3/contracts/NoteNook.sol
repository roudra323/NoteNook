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
     * @dev Registers a member with the specified name with 50 native token.
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
 * @title NoteNook
 * @dev Marketplace functionality using the CSEToken.
 */
contract NoteNook is CSEToken {
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
        bool inMarket;
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
    mapping(address => Note[]) userListedNotes; // all the notes that are listed by the user for selling
    mapping(address => Note[]) userBuyedNotes; // all the notes that are buyed by the user
    mapping(address => Note[]) resellerNotes; // all the notes that are listed for reselling
    mapping(address => uint) stackedInfo;
    mapping(uint => Voting) votingInfo;
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
            true,
            false
        );
        Notes[noteID] = note;
        userListedNotes[msg.sender].push(note);
        listedNotes.push(note);
        noteID++;
    }

    /**
     * @dev Gets all the notes that are listed by the user for selling.
     * @return The information about all the notes that are listed by the user for selling.
     */
    function getListedNotesUser() external view returns (Note[] memory) {
        return listedNotes[msg.sender];
    }

    /**
     * @dev Gets all the notes that are buyed by the user.
     * @return The information about all the notes that are buyed by the user.
     */
    function getBuyedNoteUser() external view returns (Note[] memory) {
        return userBuyedNotes[msg.sender];

    /**
     * @dev Gets all the notes that are listed for reselling.
     * @return The information about all the notes that are listed for reselling.
     */

    function getResellerNotes() external view returns (Note[] memory) {
        return resellerNotes[msg.sender];

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
    function getAllListedNoteInfo() external view returns (Note[] memory) {
        return listedNotes;
    }

    /**
     * @dev Retrieves array about approved notes.
     * @return The information about all approved notes.
     */
    function getAllApprovedNotes() external view returns (Note[] memory) {
        return approvedNotes;
    }

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
                Notes[i].inMarket = true;
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
        uint ownerPrice = (Notes[_id].price * 90) / 100;
        transfer(Notes[_id].owner, ownerPrice);

        if (Notes[_id].owner != Notes[_id].creator) {
            transfer(Notes[_id].creator, (Notes[_id].price * 10) / 100);
        }

        Notes[_id].owner = msg.sender;
        Notes[_id].inMarket = false;
        userBuyedNotes[msg.sender].push(Notes[_id]);
    }

    /**
     * @dev Resells a specific note.
     * @param _noteID The ID of the note to resell.
     * @param index The index of the note in the array.
     * @param _price The price of the note.
     */

    function resell(
        uint _noteID,
        uint index,
        uint _price
    ) external {
        require(isRegistered(), "You are not registered!");
        require(Notes[_noteID].isApproved, "Note isn't Approved");
        require(_noteID < noteID, "Invalid note");
        Notes[_noteID].inMarket = true;
        Notes[_noteID].price = _price;
        resellerNotes[msg.sender].push(Notes[_noteID]);
    }
}
