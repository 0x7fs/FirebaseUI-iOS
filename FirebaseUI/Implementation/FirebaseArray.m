/*
 * Firebase UI Bindings iOS Library
 *
 * Copyright © 2015 Firebase - All Rights Reserved
 * https://www.firebase.com
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binaryform must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY FIREBASE AS IS AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL FIREBASE BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Firebase/Firebase.h>

#import "FirebaseArray.h"

@implementation FirebaseArray

#pragma mark -
#pragma mark Initializer methods

- (instancetype)initWithRef:(Firebase *)ref;
{
    return [self initWithQuery:ref];
}

- (instancetype)initWithQuery:(Firebase *)ref;
{
    self = [super init];
    if (self) {
        self.snapshots = [NSMutableArray array];
        self.ref = ref;
        
        [self initListeners];
    }
    return self;
}


#pragma mark -
#pragma mark Memory management methods

- (void)dealloc;
{
    //TODO: Consider keeping track of these and only removing them if they are explicitly added here
    [self.ref removeAllObservers];
}

#pragma mark -
#pragma mark Private API methods

- (void)initListeners;
{
    [self.ref observeEventType:FEventTypeChildAdded andPreviousSiblingKeyWithBlock:^(FDataSnapshot *snapshot, NSString *previousChildKey) {
        NSUInteger index = [self indexForKey:previousChildKey] + 1;

        [self.snapshots insertObject:snapshot atIndex:index];
        
        [self.delegate childAdded:snapshot atIndex:index];
    }];
    
    [self.ref observeEventType:FEventTypeChildMoved andPreviousSiblingKeyWithBlock:^(FDataSnapshot *snapshot, NSString *previousChildKey) {
        NSUInteger fromIndex = [self indexForKey:snapshot.key];
        [self.snapshots removeObjectAtIndex:fromIndex];
        
        NSUInteger toIndex = [self indexForKey:previousChildKey] + 1;
        [self.snapshots insertObject:snapshot atIndex:toIndex];
        
        [self.delegate childMoved:snapshot fromIndex:fromIndex toIndex:toIndex];
    }];

    [self.ref observeEventType:FEventTypeChildChanged andPreviousSiblingKeyWithBlock:^(FDataSnapshot *snapshot, NSString *previousChildKey) {
        NSUInteger index = [self indexForKey:snapshot.key];
        
        [self.snapshots replaceObjectAtIndex:index withObject:snapshot];

        [self.delegate childChanged:snapshot atIndex:index];
    }];
    
    [self.ref observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        NSUInteger index = [self indexForKey:snapshot.key];

        [self.snapshots removeObjectAtIndex:index];

        [self.delegate childRemoved:snapshot atIndex:index];
    }];
}

- (NSUInteger)indexForKey:(NSString *)key;
{
    if (!key) return -1;
    
    for (NSUInteger index = 0; index < [self.snapshots count]; index++) {
        if ([key isEqualToString:[(FDataSnapshot *)[self.snapshots objectAtIndex:index] key]]) {
            return index;
        }
    }
    
    @throw [NSException exceptionWithName:@"KeyNotFound" reason:@"" userInfo:@{}];
}


#pragma mark -
#pragma mark Public API methods

- (NSUInteger)count;
{
    return [self.snapshots count];
}

- (FDataSnapshot *)objectAtIndex:(NSUInteger)index;
{
    return (FDataSnapshot *)[self.snapshots objectAtIndex:index];
}

- (Firebase *)refForIndex:(NSUInteger)index;
{
    return [(FDataSnapshot *)[self.snapshots objectAtIndex:index] ref];
}

@end
