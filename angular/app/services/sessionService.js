angular.module('genie').service('sessionService', function() {
    this.setUserId = function(userId) {
        localStorage.setItem('userId', userId);
    };

    this.getUserId = function() {
        return localStorage.getItem('userId');
    };

    this.setSessionId = function(sessionId) {
        localStorage.setItem('sessionId', sessionId);
    };

    this.getSessionId = function() {
        return localStorage.getItem('sessionId');
    };
    
    this.setFirstTimeLogin = function(value) {
        localStorage.setItem('firstTimeLogin', value); // Store as a string
    };

    this.getFirstTimeLogin = function() {
        return localStorage.getItem('firstTimeLogin') === 'true'; // Return as boolean
    };

    this.clearSession = function() {
        localStorage.removeItem('userId');
        localStorage.removeItem('firstTimeLogin');
    };
    
    
});