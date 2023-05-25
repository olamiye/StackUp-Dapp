// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract StackUp {
    // Enum to represent different player quest statuses
    enum PlayerQuestStatus {
        NOT_JOINED,
        JOINED,
        SUBMITTED,
        REJECTED,
        APPROVED
    }

    // Struct to store quest details
    struct Quest {
        uint256 questId;
        uint256 numberOfPlayers;
        string title;
        uint8 reward;
        uint256 numberOfRewards;
        uint256 startTime;  // Start time of the quest
        uint256 endTime;    // End time of the quest
    }

    // Struct to store player submission details
    struct Submission {
        address player;
        uint256 questId;
        string description;
        bool rewarded;
    }

    address public admin;
    uint256 public nextQuestId;
    mapping(uint256 => Quest) public quests;
    mapping(address => mapping(uint256 => PlayerQuestStatus)) public playerQuestStatuses;
    Submission[] public submissions;

    constructor() {
        admin = msg.sender;
    }

    // Function to create a new quest
    function createQuest(
        string calldata title_,
        uint8 reward_,
        uint256 numberOfRewards_,
        uint256 startTime_,
        uint256 endTime_
    ) external {
        require(msg.sender == admin, "Only the admin can create quests");
        require(endTime_ > startTime_, "Invalid quest end time");

        // Assign the quest details to the nextQuestId
        quests[nextQuestId].questId = nextQuestId;
        quests[nextQuestId].title = title_;
        quests[nextQuestId].reward = reward_;
        quests[nextQuestId].numberOfRewards = numberOfRewards_;
        quests[nextQuestId].startTime = startTime_;
        quests[nextQuestId].endTime = endTime_;
        nextQuestId++;
    }

    // Function for players to join a quest
    function joinQuest(uint256 questId) external questExists(questId) {
        require(
            playerQuestStatuses[msg.sender][questId] == PlayerQuestStatus.NOT_JOINED,
            "Player has already joined/submitted this quest"
        );
        require(block.timestamp >= quests[questId].startTime, "Quest has not started yet");
        require(block.timestamp <= quests[questId].endTime, "Quest has already ended");

        // Update the player's quest status to JOINED
        playerQuestStatuses[msg.sender][questId] = PlayerQuestStatus.JOINED;

        Quest storage thisQuest = quests[questId];
        thisQuest.numberOfPlayers++;
    }

    // Function for players to submit a quest
    function submitQuest(uint256 questId, string calldata description) external questExists(questId) {
        require(
            playerQuestStatuses[msg.sender][questId] == PlayerQuestStatus.JOINED,
            "Player must first join the quest"
        );
        require(block.timestamp <= quests[questId].endTime, "Quest has already ended");

        // Update the player's quest status to SUBMITTED
        playerQuestStatuses[msg.sender][questId] = PlayerQuestStatus.SUBMITTED;

        // Add the submission to the submissions array
        submissions.push(Submission({
            player: msg.sender,
            questId: questId,
            description: description,
            rewarded: false
        }));
    }

    // Function for the admin to review a submission
    function reviewSubmission(uint256 submissionIndex, bool approve) external onlyAdmin {
        require(submissionIndex < submissions.length, "Invalid submission index");

        Submission storage submission = submissions[submissionIndex];

        require(
            playerQuestStatuses[submission.player][submission.questId] == PlayerQuestStatus.SUBMITTED,
            "Invalid submission"
        );

        if (approve) {
            // Update the player's quest status to APPROVED
            playerQuestStatuses[submission.player][submission.questId] = PlayerQuestStatus.APPROVED;
            submission.rewarded = true;
        } else {
            // Update the player's quest status to REJECTED
            playerQuestStatuses[submission.player][submission.questId] = PlayerQuestStatus.REJECTED;
        }
    }

    // Modifier to check if a quest exists
    modifier questExists(uint256 questId) {
        require(quests[questId].reward != 0, "Quest does not exist");
        _;
    }

    // Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can perform this action");
        _;
    }
}
