// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

contract MovieVoting {
    enum VotingState { Created, Ongoing, Ended }

    struct Voter {
        bool hasVoted;
        string votedMovie;
    }
    
    struct MoviePoll {
        string[] movies;
        mapping (address => Voter) voters;
        mapping (string => uint) votes;
        uint16 voteCount;
        address creator;
        VotingState state;
        uint endTime;
        string winner;
    }

    // Poll ID to MoviePoll mapping
    mapping(uint => MoviePoll) public polls;
    // Creator address to poll IDs mapping
    mapping(address => uint[]) public creatorPolls;
   
    // Counter for new poll IDs
    uint private pollIdCounter;
    
    // chagne to immutable
    address immutable owner;

    event PollCreated(uint pollId, address creator);
    event VoteCasted(uint pollId, uint votes);
    event PollEnded(uint pollId, string winningMovie);

    error NotOwner(address caller);
    error PollNotOngoing();
    error PollIsOngoing();
    error PollAlreadyEnded();
    error AlreadyVoted();
    error MovieNotFound();
    error InvalidPollId();

    modifier onlyOwner(uint _pollId) {
        require(polls[_pollId].creator == msg.sender, "Only owner can call this function");
        _;
    }

    modifier isOngoing(uint _pollId) {
        require(polls[_pollId].state == VotingState.Ongoing, "Poll is not ongoing");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createPoll(string[] memory _movies) external {
        require(_movies.length > 0, "At least one movie required");

        uint newPollId = pollIdCounter++;
        MoviePoll storage newPoll = polls[newPollId];
        newPoll.movies = _movies;
        newPoll.creator = msg.sender;
        newPoll.state = VotingState.Created;

        creatorPolls[msg.sender].push(newPollId);
        polls[newPollId].creator = msg.sender;

        emit PollCreated(newPollId, msg.sender);
    }

    function startPoll(uint _pollId, uint _durationMinutes) external onlyOwner(_pollId) {
        MoviePoll storage moviePoll = polls[_pollId];

        // Make these combined
        if (moviePoll.state == VotingState.Ongoing) {
            revert PollIsOngoing();
        }

        if (moviePoll.state == VotingState.Ended) {
            revert PollAlreadyEnded();
        }

        moviePoll.state = VotingState.Ongoing;
        moviePoll.endTime = block.timestamp + _durationMinutes * 1 minutes;
    }

    function vote(uint _pollId, string calldata _movie) external {
        MoviePoll storage moviePoll = polls[_pollId];
        Voter storage voter = moviePoll.voters[msg.sender];

        if (voter.hasVoted) {
            revert AlreadyVoted();
        }

        if (moviePoll.state == VotingState.Ended) {
            revert PollAlreadyEnded();
        }

        bool movieFound = false;

        for (uint i = 0; i < moviePoll.movies.length; i++) {
            if (keccak256(bytes(moviePoll.movies[i])) == keccak256(bytes(_movie))) {
                movieFound = true;
                break;
            }
        }

        if (!movieFound) {
            revert MovieNotFound();
        }

        ++moviePoll.votes[_movie];
        ++moviePoll.voteCount;

        if(moviePoll.votes[_movie] > moviePoll.votes[moviePoll.winner]) {
            moviePoll.winner = _movie;
        }

        voter.hasVoted = true;
        voter.votedMovie = _movie;
        // voter = Voter(true, _movie);

        emit VoteCasted(_pollId, moviePoll.voteCount);
    }

    function endPoll(uint _pollId) external onlyOwner(_pollId) {
        MoviePoll storage moviePoll = polls[_pollId];

        require(moviePoll.state == VotingState.Ongoing, "Poll is not ongoing");
        require(block.timestamp >= moviePoll.endTime, "Voting period has not ended yet");

        moviePoll.state = VotingState.Ended;

        emit PollEnded(_pollId, moviePoll.winner );
    }

    function getWinner(uint _pollId) external view returns (string memory) {
        MoviePoll storage moviePoll = polls[_pollId];
        require(moviePoll.state == VotingState.Ended, "Poll has not ended yet");
        return moviePoll.winner;
    }

    function getPollsByCreator() external view returns (uint[] memory) {
        return creatorPolls[msg.sender];
    }

    function getVotesForMovie(uint _pollId, string calldata _movie) external view returns (uint) {
        return polls[_pollId].votes[_movie];
    }

    fallback() external payable {
        revert("This contract does not accept ETH");
    }

    receive() external payable {
        revert("This contract does not accept ETH");
    }
}
