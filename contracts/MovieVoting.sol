// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

contract MovieVoting {
    // Röstning öppen under viss tid    
    // Vinnande film presenteras vid avslut
    // Varje omröstning kopplad till användare som skapat den
    enum VotingState { Created, Ongoing, Ended }

    struct Voter {
         bool hasVoted;
         string votedMovie;
    }
    
    struct MoviePoll {
        string[] movies;
        mapping (string => uint) votes;
        mapping (address => Voter) voters;
        address creator;
        VotingState state;
        uint endTime;
        // uint id;
        string winner;
    }

    // Mapping user to their polls
    mapping(address => MoviePoll[]) public userPolls;
    address public owner;

    event PollCreated(uint pollIndex, address creator);
    event VoteCasted(uint pollIndex, string movie, uint votes);
    event PollEnded(uint pollIndex, string winningMovie);

    error NotOwner(address caller);
    error PollNotOngoing();
    error PollAlreadyStarted();
    error PollEndedEarly();
    error AlreadyVoted();
    error MovieNotFound();

    // error NotOwner(address sender,"Only owner can call this function");
    modifier onlyOwner(address _creator, uint _pollIndex) {
        require(userPolls[_creator][_pollIndex].creator == msg.sender, "Only owner can call this function");
        _;
    }

    modifier isOngoing(address _creator, uint _pollIndex) {
        require(userPolls[_creator][_pollIndex].state == VotingState.Ongoing, "Poll is not ongoing");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Funktion för att skapa röstning
    function createPoll(string[] memory _movies) public {
        require(_movies.length > 0, "At least one movie required");

        MoviePoll storage newPoll = userPolls[msg.sender].push();
        newPoll.movies = _movies;
        newPoll.creator = msg.sender;
        newPoll.state = VotingState.Created;

        emit PollCreated(userPolls[msg.sender].length - 1, msg.sender);
    }

    // Funktion för att starta röstning
    function startPoll(uint _moviePollId, uint _durationMinutes) public {
        MoviePoll storage moviePoll = userPolls[msg.sender][_moviePollId];

        if (moviePoll.creator != msg.sender){
           revert NotOwner(msg.sender);
        }

        if(moviePoll.state != VotingState.Created) {
            revert PollAlreadyStarted();
        }

        // require(moviePoll.state == VotingState.Created, "Poll is already started");
        // lägg till VotingState.Ended

        moviePoll.state = VotingState.Ongoing;
        moviePoll.endTime = block.timestamp + _durationMinutes * 1 minutes;
    }

    // Funktion för att lägga röstning
    function vote(address _creator, uint _pollIndex, string calldata _movie) public {
        MoviePoll storage moviePoll = userPolls[_creator][_pollIndex];
        Voter storage voter = moviePoll.voters[msg.sender];

        if(voter.hasVoted){
            revert AlreadyVoted();
        }
        //require(!voter.hasVoted, "You have already voted");
       // require(block.timestamp <= moviePoll.endTime, "Voting period ended");

        // kolla om filmen finns 
        bool movieFound = false;

        for (uint i = 0; 0 < moviePoll.movies.length; i++) {
            if (keccak256(bytes(moviePoll.movies[i])) == keccak256(bytes(_movie))) {
                movieFound = true;
                break;
            }
        }

        if(!movieFound) {
            revert MovieNotFound();
        }

        moviePoll.votes[_movie]++;
        voter.hasVoted = true;
        voter.votedMovie = _movie;

       // emit VoteCasted(_pollIndex, _movie, msg.sender);
    }

    function endPoll(uint _pollIndex) public onlyOwner(msg.sender, _pollIndex) {
        MoviePoll storage moviePoll = userPolls[msg.sender][_pollIndex];

        require(moviePoll.state == VotingState.Ongoing, "Poll is not ongoing");
        require(block.timestamp >= moviePoll.endTime, "Voting period has not ended yet");

        moviePoll.state = VotingState.Ended;

        string memory winningMovie;
        uint maxVotes = 0;

        for (uint i = 0; i < moviePoll.movies.length; i++) {
            string memory movie = moviePoll.movies[i];
            uint voteCount = moviePoll.votes[movie];

            if (voteCount > maxVotes) {
                maxVotes = voteCount;
                winningMovie = movie;
            }
        }

        moviePoll.winner = winningMovie;
        //emit PollEnded(msg.sender, _pollIndex, winningMovie)
    }

    function getWinner(uint _pollIndex) public view returns (string memory) {
        MoviePoll storage moviePoll = userPolls[msg.sender][_pollIndex];
        require(moviePoll.state == VotingState.Ended, "Poll has not ended yet");
        return moviePoll.winner;
    }

    fallback() external payable {
        revert("This contract does not accept ETH");
    }

    receive() external payable {
        revert("This contract does not accept ETH");
    }

}