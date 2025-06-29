(function () {
'use strict';

/*
 * AngularJS Toaster
 * Version: 0.4.10+
 *
 * Copyright 2013-2014 Jiri Kavulak.
 * All Rights Reserved.
 * Use, reproduction, distribution, and modification of this code is subject to the terms and
 * conditions of the MIT license, available at http://www.opensource.org/licenses/mit-license.php
 *
 * Author: Jiri Kavulak
 * Related to project of John Papa and Hans Fjällemark
 * 
 * Help link http://embed.plnkr.co/1PP56s/
 */

angular.module('toaster', ['ngAnimate'])
.constant('toasterConfig', {
    'limit': 0,                   // limits max number of toasts
    'tap-to-dismiss': true,
    'close-button': false,
    'newest-on-top': true,
    //'fade-in': 1000,            // done in css
    //'on-fade-in': undefined,    // not implemented
    //'fade-out': 1000,           // done in css
    //'on-fade-out': undefined,   // not implemented
    //'extended-time-out': 1000,  // not implemented
    'time-out': 5000, // Set timeOut and extendedTimeout to 0 to make it sticky
    'icon-classes': {
        error: 'toast-error',
        info: 'toast-info',
        wait: 'toast-wait',
        success: 'toast-success',
        warning: 'toast-warning'
    },
    'body-output-type': '', // Options: '', 'trustedHtml', 'template', 'templateWithData'
    'body-template': 'toasterBodyTmpl.html',
    'icon-class': 'toast-info',
    'position-class': 'toast-top-right', // Options (see CSS):
                                         // 'toast-top-full-width', 'toast-bottom-full-width', 'toast-center',
                                         // 'toast-top-left', 'toast-top-center', 'toast-top-rigt',
                                         // 'toast-bottom-left', 'toast-bottom-center', 'toast-bottom-rigt',
    'title-class': 'toast-title',
    'message-class': 'toast-message',
    'prevent-duplicates': false,
    'mouseover-timer-stop': true // stop timeout on mouseover and restart timer on mouseout
})
.service('toaster', ['$rootScope', 'toasterConfig', function ($rootScope, toasterConfig) {
    this.pop = function (type, title, body, timeout, bodyOutputType, clickHandler, toasterId) {
        if (angular.isObject(type)) {
            var params = type; // Enable named parameters as pop argument
            this.toast = {
                type: params.type,
                title: params.title,
                body: params.body,
                timeout: params.timeout,
                bodyOutputType: params.bodyOutputType,
                clickHandler: params.clickHandler
            };
            toasterId = params.toasterId;
        } else {
            this.toast = {
                type: type,
                title: title,
                body: body,
                timeout: timeout,
                bodyOutputType: bodyOutputType,
                clickHandler: clickHandler
            };
        }
        $rootScope.$emit('toaster-newToast', toasterId);
    };

    this.clear = function () {
        $rootScope.$emit('toaster-clearToasts');
    };

    // Create one method per icon class, to allow to call toaster.info() and similar
    for (var type in toasterConfig['icon-classes']) {
        this[type] = (function (toasterType) {
            return function(title, body, timeout, bodyOutputType, clickHandler, toasterId) {
                if (angular.isString(title)) {
                    this.pop(toasterType, title, body, timeout, bodyOutputType, clickHandler, toasterId);
                } else { // 'title' is actually an object with options
                    this.pop(angular.extend(title, { type: toasterType }));
                }
            };
        })(type);
    }
}])
.factory('toasterEventRegistry', function($rootScope) {
    var deregisterNewToast = null,
        deregisterClearToasts = null,
        newToastEventSubscribers = [],
        clearToastsEventSubscribers = [],
        toasterFactory;

    deregisterNewToast = $rootScope.$on('toaster-newToast', function (event, toasterId) {
        for (var i = 0, len = newToastEventSubscribers.length; i < len; i++) {
            newToastEventSubscribers[i](event, toasterId);
        }
    });
    deregisterClearToasts = $rootScope.$on('toaster-clearToasts', function (event) {
        for (var i = 0, len = clearToastsEventSubscribers.length; i < len; i++) {
            clearToastsEventSubscribers[i](event);
        }
    });

    toasterFactory = {
        subscribeToNewToastEvent: function(onNewToast) {
            newToastEventSubscribers.push(onNewToast);
        },
        subscribeToClearToastsEvent: function(onClearToasts) {
            clearToastsEventSubscribers.push(onClearToasts);
        },
        unsubscribeToNewToastEvent: function(onNewToast) {
            var index = newToastEventSubscribers.indexOf(onNewToast);
            if (index >= 0)
                newToastEventSubscribers.splice(index, 1);
            if (newToastEventSubscribers.length === 0)
                deregisterNewToast();
        },
        unsubscribeToClearToastsEvent: function(onClearToasts) {
            var index = clearToastsEventSubscribers.indexOf(onClearToasts);
            if (index >= 0)
                clearToastsEventSubscribers.splice(index, 1);
            if (clearToastsEventSubscribers.length === 0)
                deregisterClearToasts();
        }
    };
    return {
        subscribeToNewToastEvent: toasterFactory.subscribeToNewToastEvent,
        subscribeToClearToastsEvent: toasterFactory.subscribeToClearToastsEvent,
        unsubscribeToNewToastEvent: toasterFactory.unsubscribeToNewToastEvent,
        unsubscribeToClearToastsEvent: toasterFactory.unsubscribeToClearToastsEvent
    };
})
.directive('toasterContainer', ['$parse', '$rootScope', '$interval', '$sce', 'toasterConfig', 'toaster', 'toasterEventRegistry',
function ($parse, $rootScope, $interval, $sce, toasterConfig, toaster, toasterEventRegistry) {
    return {
        replace: true,
        restrict: 'EA',
        scope: true, // creates an internal scope for this directive (one per directive instance)
        link: function (scope, elm, attrs) {
            var id = 0,
                mergedConfig;

            // Merges configuration set in directive with default one
            mergedConfig = angular.extend({}, toasterConfig, scope.$eval(attrs.toasterOptions));

            scope.config = {
                toasterId: mergedConfig['toaster-id'],
                position: mergedConfig['position-class'],
                title: mergedConfig['title-class'],
                message: mergedConfig['message-class'],
                tap: mergedConfig['tap-to-dismiss'],
                closeButton: mergedConfig['close-button'],
                animation: mergedConfig['animation-class'],
                mouseoverTimer: mergedConfig['mouseover-timer-stop']
            };

            scope.$on("$destroy", function () {
                toasterEventRegistry.unsubscribeToNewToastEvent(scope._onNewToast);
                toasterEventRegistry.unsubscribeToClearToastsEvent(scope._onClearToasts);
            });

            function setTimeout(toast, time) {
                toast.timeoutPromise = $interval(function () {
                    $interval.cancel(toast.timeoutPromise);
                    scope.removeToast(toast.id);
                }, time, 1);
            }

            scope.configureTimer = function (toast) {
                var timeout = angular.isNumber(toast.timeout) ? toast.timeout : mergedConfig['time-out'];
                if (timeout > 0)
                    setTimeout(toast, timeout);
            };

            function addToast(toast) {
                toast.type = mergedConfig['icon-classes'][toast.type];
                if (!toast.type)
                    toast.type = mergedConfig['icon-class'];

                // Prevent adding duplicate toasts if it's set
                if (mergedConfig['prevent-duplicates'] === true &&
                    scope.toasters.length > 0 &&
                    scope.toasters[scope.toasters.length - 1].body === toast.body)
                    return;

                toast.id = ++id;

                // Set the toast.bodyOutputType to the default if it isn't set
                toast.bodyOutputType = toast.bodyOutputType || mergedConfig['body-output-type'];
                switch (toast.bodyOutputType) {
                    case 'trustedHtml':
                        toast.html = $sce.trustAsHtml(toast.body);
                        break;
                    case 'template':
                        toast.bodyTemplate = toast.body || mergedConfig['body-template'];
                        break;
                    case 'templateWithData':
                        var fcGet = $parse(toast.body || mergedConfig['body-template']);
                        var templateWithData = fcGet(scope);
                        toast.bodyTemplate = templateWithData.template;
                        toast.data = templateWithData.data;
                        break;
                }

                scope.configureTimer(toast);

                if (mergedConfig['newest-on-top'] === true) {
                    scope.toasters.unshift(toast);
                    if (mergedConfig['limit'] > 0 && scope.toasters.length > mergedConfig['limit']) {
                        scope.toasters.pop();
                    }
                } else {
                    scope.toasters.push(toast);
                    if (mergedConfig['limit'] > 0 && scope.toasters.length > mergedConfig['limit']) {
                        scope.toasters.shift();
                    }
                }
            }

            scope.toasters = [];

            scope._onNewToast = function (event, toasterId) {
                // Compatibility: if toaster has no toasterId defined, and if call to display
                // hasn't either, then the request is for us
                if (scope.config.toasterId === undefined && toasterId === undefined ||
                        // Otherwise, we check if the event is for this toaster
                        toasterId !== undefined && toasterId === scope.config.toasterId)
                    addToast(toaster.toast);
            };
            scope._onClearToasts = function (event) {
                scope.toasters.splice(0, scope.toasters.length);
            };
            toasterEventRegistry.subscribeToNewToastEvent(scope._onNewToast);
            toasterEventRegistry.subscribeToClearToastsEvent(scope._onClearToasts);
        },
        controller: ['$scope', '$element', '$attrs', function ($scope, $element, $attrs) {
            // Called on mouseover
            $scope.stopTimer = function (toast) {
                if ($scope.config.mouseoverTimer === true) {
                    if (toast.timeoutPromise) {
                        $interval.cancel(toast.timeoutPromise);
                        toast.timeoutPromise = null;
                    }
                }
            };

            // Called on mouseout
            $scope.restartTimer = function (toast) {
                if ($scope.config.mouseoverTimer === true) {
                    if (!toast.timeoutPromise)
                        $scope.configureTimer(toast);
                } else if (toast.timeoutPromise === null) {
                    $scope.removeToast(toast.id);
                }
            };

            $scope.removeToast = function (id) {
                var i = 0;
                for (; i < $scope.toasters.length; i++) {
                    if ($scope.toasters[i].id === id) {
                        $scope.toasters.splice(i, 1);
                        break;
                    }
                }
            };

            $scope.click = function (toast, isCloseButton) {
                if ($scope.config.tap === true || isCloseButton === true) {
                    var removeToast = true;
                    if (toast.clickHandler) {
                        if (angular.isFunction(toast.clickHandler)) {
                            removeToast = toast.clickHandler(toast, isCloseButton);
                        } else if (angular.isFunction($scope.$parent.$eval(toast.clickHandler))) {
                            removeToast = $scope.$parent.$eval(toast.clickHandler)(toast, isCloseButton);
                        } else {
                            console.log("TOAST-NOTE: Your click handler is not inside a parent scope of toaster-container.");
                        }
                    }
                    if (removeToast) {
                        $scope.removeToast(toast.id);
                    }
                }
            };
        }],
        template:
        '<div id="toast-container" ng-class="[config.position, config.animation]">' +
          '<div ng-repeat="toaster in toasters" class="toast" ng-class="toaster.type" ng-click="click(toaster)" ng-mouseover="stopTimer(toaster)" ng-mouseout="restartTimer(toaster)">' +
            '<button class="toast-close-button" ng-show="config.closeButton" ng-click="click(toaster, true)">&times;</button>' +
            '<div ng-class="config.title">{{toaster.title}}</div>' +
            '<div ng-class="config.message" ng-switch on="toaster.bodyOutputType">' +
              '<div ng-switch-when="trustedHtml" ng-bind-html="toaster.html"></div>' +
              '<div ng-switch-when="template"><div ng-include="toaster.bodyTemplate"></div></div>' +
              '<div ng-switch-when="templateWithData"><div ng-include="toaster.bodyTemplate"></div></div>' +
              '<div ng-switch-default >{{toaster.body}}</div>' +
            '</div>' +
          '</div>' +
        '</div>'
    };
}]);
})(window, document);
