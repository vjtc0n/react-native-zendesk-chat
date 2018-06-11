//
//  RNZendeskChat.m
//  Tasker
//
//  Created by Jean-Richard Lai on 11/23/15.
//  Copyright © 2015 Facebook. All rights reserved.
//

#import "RNZendeskChatModule.h"
#import <ZDCChat/ZDCChat.h>

@implementation RNZendeskChatModule
{
  bool hasListeners;
}

RCT_EXPORT_MODULE(RNZendeskChatModule);

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"ChatLogEvent"];
}

-(void)startObserving
{
  hasListeners = YES;

  dispatch_sync(dispatch_get_main_queue(), ^{
    [[ZDCChatAPI instance] addObserver:self forChatLogEvents:@selector(chatEvent)];
  });
}

-(void)stopObserving
{
  hasListeners = NO;
  [[ZDCChatAPI instance] removeObserverForChatLogEvents:self];
}

-(void)chatEvent
{
  if (!hasListeners) return;

  NSArray *events = [[ZDCChatAPI instance] livechatLog];
  if (events == nil || events.count == 0) return;
  ZDCChatEvent *event = [events lastObject];
  if (event == nil) return;

  NSString *eventType;
  switch (event.type) {
    case ZDCChatEventTypeUnknown:
      eventType = @"Unknown";
      break;
    case ZDCChatEventTypeMemberJoin:
      eventType = @"MemberJoin";
      break;
    case ZDCChatEventTypeMemberLeave:
      eventType = @"MemberLeave";
      break;
    case ZDCChatEventTypeSystemMessage:
      eventType = @"SystemMessage";
      break;
    case ZDCChatEventTypeTriggerMessage:
      eventType = @"TriggerMessage";
      break;
    case ZDCChatEventTypeAgentMessage:
      eventType = @"AgentMessage";
      break;
    case ZDCChatEventTypeVisitorMessage:
      eventType = @"VisitorMessage";
      break;
    case ZDCChatEventTypeVisitorUpload:
      eventType = @"VisitorUpload";
      break;
    case ZDCChatEventTypeAgentUpload:
      eventType = @"AgentUpload";
      break;
    case ZDCChatEventTypeRating:
      eventType = @"Rating";
      break;
    case ZDCChatEventTypeRatingComment:
      eventType = @"RatingComment";
      break;
    default:
      eventType = @"Unknown";
  }

  [self sendEventWithName:@"ChatLogEvent" body:@{
    @"eventId": event.eventId,
    @"timestamp": event.timestamp,
    @"nickname": event.nickname,
    @"displayName": event.displayName,
    @"message": event.message,
    @"type": eventType,
    @"verified": @(event.verified)
  }];
}

RCT_EXPORT_METHOD(setVisitorInfo:(NSDictionary *)options) {
  [ZDCChat updateVisitor:^(ZDCVisitorInfo *visitor) {
    if (options[@"name"]) {
      visitor.name = options[@"name"];
    }
    if (options[@"email"]) {
      visitor.email = options[@"email"];
    }
    if (options[@"phone"]) {
      visitor.phone = options[@"phone"];
    }
    visitor.shouldPersist = options[@"shouldPersist"] || NO;
  }];
}

RCT_EXPORT_METHOD(startChat:(NSDictionary *)options) {
  [self setVisitorInfo:options];

  dispatch_sync(dispatch_get_main_queue(), ^{
    [ZDCChat startChat:^(ZDCConfig *config) {
      if (options[@"department"]) {
        config.department = options[@"department"];
      }
      if (options[@"tags"]) {
        config.tags = options[@"tags"];
      }

      if (!options[@"disablePreChatForm"]) {
        config.preChatDataRequirements.name       = options[@"nameNotRequired"] ?  ZDCPreChatDataNotRequired : ZDCPreChatDataRequired;
        config.preChatDataRequirements.email      = options[@"emailNotRequired"] ? ZDCPreChatDataNotRequired : ZDCPreChatDataRequired;
        config.preChatDataRequirements.phone      = options[@"phoneNotRequired"] ? ZDCPreChatDataNotRequired : ZDCPreChatDataRequired;
        config.preChatDataRequirements.department = options[@"departmentNotRequired"] ? ZDCPreChatDataNotRequired : ZDCPreChatDataRequiredEditable;
        config.preChatDataRequirements.message    = options[@"messageNotRequired"] ? ZDCPreChatDataNotRequired : ZDCPreChatDataRequired;
      }

      if (options[@"disableTranscripts"]) {
        config.emailTranscriptAction = ZDCEmailTranscriptActionNeverSend;
      }
    }];
  });
}

RCT_REMAP_METHOD(unreadMessagesCount, unreadMessagesCountWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
  NSInteger count = [[ZDCChat instance] unreadMessagesCount];
  if (count < 0) {
    count = 0;
  }
  resolve([NSNumber numberWithInteger:count]);
}

@end
