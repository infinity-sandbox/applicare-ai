angular.module('genie').controller('homeController', function($scope, $http, $location, $window, sessionService, $document, $rootScope, $sce, $timeout) {
	var that = this;
	$scope.$watch(() => $rootScope.fileData, function(newValue) {
        if (newValue) {
            $scope.genieUrl = newValue.backend_url;
        }
    });
	var userId = sessionService.getUserId();
	var sessionId = sessionService.getSessionId();
	console.log(sessionId)
	
	$scope.logout = function() {
		$location.path('/login'); // Redirect to login page
	};

	this.sendMessage = function() {
		this.chatMessage = ''; // Clear input field
	};

	function handleClickOutside(event) {
		var isClickInsideMenu = document.querySelector('.user-menu').contains(event.target);
		if (!isClickInsideMenu) {
			$scope.$apply(() => {
				that.isUserMenuOpen = false;
			});
			$document.off('click', handleClickOutside);
		}
	}

	$scope.showChatContent = false;

	this.toggleChatContent = function() {
		$scope.showChatContent = !$scope.showChatContent;
	};

	$scope.messages = [];
	this.userQuestion = '';
	$scope.systemResponses = {};
	$scope.userId = userId;

	$scope.messages.push({
		type: 'bot',
		text: $sce.trustAsHtml('Hello! How can I assist you in exploring your data today?'),
		sessionId: sessionId,
	});
	
	$scope.lastUserQuestionForRetry = null;

	this.sendQuestion = function() {
		if ((!this.userQuestion && !$scope.retryInProgress) || $scope.loading) return;

		scrollToBottom();

		var data = {
			query: this.userQuestion,
			userId: $scope.userId,
			sessionId: sessionId
		};

		var httpReq = {
			method: 'POST',
			url: $scope.genieUrl + '/api/v1/chatbot/query',
			data: data,
			headers: {
				'Content-Type': 'application/json'
			}
		};

		// Only add the user question if it's a new one (not a retry)
		if (!$scope.retryInProgress) {
			$scope.lastUserQuestionForRetry = this.userQuestion; //
			$scope.messages.push({
				type: 'user',
				text: this.userQuestion,
				sessionId: sessionId,
			});
		}

		this.userQuestion = ''; // Clear the input field

		$scope.loading = true;
		$scope.messages.push({ type: 'bot', loading: true }); // Add loading indicator for the bot

		$http(httpReq).then(function(response) {
			$scope.messages.pop(); // Remove loading indicator
			
			if (response && response.data && response.data.system) {
				var systemResponse = response.data.system;
				var messageId = response.data.messageId || 'null';
				var formattedResponse = systemResponse                           
                                        .replace(/\n/g, '<br>')
                                        .replace(/(http[s]?:\/\/[^\s]+)/g, '<a href="$1">$1</a>');
				var trustedHtml = $sce.trustAsHtml(formattedResponse);
				$scope.messages.push({
					type: 'bot',
					text: trustedHtml,
					sessionId: sessionId,
					messageId: messageId
				});

				$scope.systemResponses[messageId] = systemResponse;
			} else{
				
				$scope.messages.push({
					type: 'bot',
					text: $sce.trustAsHtml('Connection timeout...'),
					rawText: 'Connection timeout...',
					sessionId: sessionId,
					messageId: 'null'
				});
			}
			$scope.loading = false;

		}, function errorCallback(error) {
			$scope.messages.pop();
			$scope.messages.push({
				type: 'bot',
				text: $sce.trustAsHtml('Connection timeout...'),
				rawText: 'Connection timeout...',
			});	
            scrollToBottom();
			$scope.loading = false;
		});
		
	};

	
	$scope.retry = function() {
		if ($scope.loading || !$scope.lastUserQuestionForRetry) return;

		that.userQuestion = $scope.lastUserQuestionForRetry; // Always use the last question
		$scope.retryInProgress = true;

		var lastBotMessage = $scope.messages[$scope.messages.length - 1];
		if (lastBotMessage && lastBotMessage.type === 'bot' && lastBotMessage.messageId === 'null') {
			$scope.messages.pop(); // Remove last timeout bot message
		}
        $scope.messages.pop();
		that.sendQuestion();
		$scope.retryInProgress = false;
	};


	$scope.handleKeyPress = function(event) {
		if (event.which === 13 && event.shiftKey && !$scope.loading) {
			return;
		}
		if (event.which === 13 && !$scope.loading) {
			that.sendQuestion();
		}
	};


	$scope.likeMessage = function(message) {
		message.isLiked = !message.isLiked;
		sendFeedback(message, "like");
	};

	$scope.dislikeMessage = function(message) {
		$scope.dislikedMessage = message;
		document.getElementById('feedbackBox').style.display = 'block';
		//document.querySelector('.chat-input-container').style.display = 'none';
		document.querySelector('.message-box-content').style.height = '0px';
		document.querySelector('.message-box-content').style.minHeight = '39vh';

		setTimeout(() => {
			document.querySelector('.chat-messages').scrollTop = document.querySelector('.chat-messages').scrollHeight;
		}, 100);
	};

	$scope.submitFeedback = function() {
		if ($scope.dislikedMessage) {
			sendFeedback($scope.dislikedMessage, "dislike");
		} else {
			console.error("No message selected for feedback submission.");
		}
	};

	function sendFeedback(message, rating) {
		var feedbackData = {
			userId: $scope.userId,
			sessionId: message.sessionId,
			messageId: message.messageId,
			rating: rating,
			feedbackText: that.feedbackText || ""
		};

		var httpReq = {
			method: 'POST',
			url: $scope.genieUrl + '/api/v1/chatbot/reaction',
			data: feedbackData,
			headers: {
				'Content-Type': 'application/json'
			}
		};

		$http(httpReq).then(function(response) {
			if (rating === "dislike") {
				message.isDisliked = true;
			}
		}).catch(function(error) {
			console.error('Error while sending feedback:', error);
		}).finally(function() {
			that.feedbackText = '';
			$scope.closeFeedbackBox();
		});
	}


	$scope.regenerateResponse = function(message) {
		scrollToBottom();
		
		var regeneratePayload = {
			query: $sce.getTrustedHtml(message.text),
			userId: $scope.userId,
			sessionId: message.sessionId,
			messageId: message.messageId
		};

		var httpReq = {
			method: 'POST',
			url: $scope.genieUrl + '/api/v1/chatbot/regenerate',
			data: regeneratePayload,
			headers: {
				'Content-Type': 'application/json'
			}
		};

		$scope.loading = true;
		$scope.messages.push({ type: 'bot', loading: true });

		$http(httpReq).then(function(response) {
			$scope.messages.pop();

			var systemResponse = response.data.system || "Regenerated response is null";
			var messageId = response.data.messageId || regeneratePayload.messageId;
            var formattedResponse = systemResponse.replace(/\n/g, '<br>');
            
			$scope.messages.push({
				type: 'bot',
				text: $sce.trustAsHtml(formattedResponse),
				sessionId: message.sessionId,
				messageId: messageId
			});

			$scope.systemResponses[messageId] = systemResponse;

		}).catch(function(error) {
			$scope.messages.pop();
			$scope.messages.push({
				type: 'bot',
				text: 'Error occurred while regenerating, please try again.'
			});
		}).finally(function() {
			$scope.loading = false;
		});
	};


	$scope.closeFeedbackBox = function(event) {
		document.getElementById('feedbackBox').style.display = 'none';
		//document.querySelector('.chat-input-container').style.display = 'flex';
	};

	$scope.$on('$destroy', function() {
		$document.off('click', handleClickOutside);
	});
	
	function scrollToBottom() {
		setTimeout(() => {
			const chatMessages = document.querySelector('.chat-messages');
			if (chatMessages) {
				chatMessages.scrollTop = chatMessages.scrollHeight;
			}
		}, 100);
	}
	
	$scope.isRecording = false;  // Track if the recording is in progress
	this.userQuestion = '';     // Store the transcribed text
	let recordingTimer; // Timer interval variable
	let seconds = 0;

	// Check for browser support
	if (!('webkitSpeechRecognition' in window)) {
		alert("Speech Recognition API not supported in this browser.");
	}

	// Initialize Speech Recognition
	var recognition = new webkitSpeechRecognition();
	recognition.continuous = true;  // Continuously listen for speech
	recognition.interimResults = true; // Provide real-time transcription

	recognition.onresult = (event) => {
		var result = event.results[event.resultIndex];
		if (result.isFinal) {
			$scope.$apply(() => {
				this.userQuestion += result[0].transcript + ' ';
			});
		}
	};

	// When speech recognition starts
	recognition.onstart = function() {
		$scope.$apply(function() {
			$scope.isRecording = true;
		});
	};

	// When speech recognition ends
	recognition.onend = function() {
		if ($scope.isRecording) {
			$scope.$apply(function() {
				$scope.isRecording = false;
			});
		}
	};

	$scope.startStopRecording = function() {
    if ($scope.isRecording) {
        // Stop the recording
        $scope.isRecording = false; 
        clearInterval(recordingTimer); 
        $scope.formattedTime = "00:00";
        $scope.showListening = false;
        recognition.stop();
    } else {
        $scope.showListening = false;
        clearInterval(recordingTimer);
        $timeout(function() {
            $scope.showListening = true; 
            $scope.isRecording = true; 
            seconds = 0; 
            updateTimer();
            recordingTimer = setInterval(updateTimer, 1000);
        }, 1500);

        recognition.start(); 
    }
};

function updateTimer() {
    seconds++;
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;

    // Safely apply changes
    if (!$scope.$$phase) {
        $scope.$apply(() => {
            $scope.formattedTime = `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
        });
    } else {
        $scope.formattedTime = `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
}

});
