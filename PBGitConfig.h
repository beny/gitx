//
//  PBGitConfig.h
//  GitX
//
//  Created by Pieter de Bie on 14-10-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PBGitConfig : NSObject {
	NSString *repositoryPath;
}
- init;
- initWithRepositoryPath:(NSString *)path;
@end
