//
//  PBGitSidebar.h
//  GitX
//
//  Created by Pieter de Bie on 9/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBViewController.h"


@interface PBGitSidebarController : PBViewController {
	IBOutlet NSWindow *window;
	IBOutlet NSOutlineView *sourceView;
	IBOutlet NSView *sourceListControlsView;
	IBOutlet NSPopUpButton *actionButton;
	IBOutlet NSSegmentedControl *remoteControls;

	NSMutableArray *items;

	/* Specific things */
	PBSourceViewItem *stage;

	PBSourceViewItem *branches, *remotes, *tags;

	PBGitHistoryController *historyViewController;
	PBGitCommitController *commitViewController;
}

- (void) selectStage;
- (void) selectCurrentBranch;

- (NSMenu *) menuForRow:(NSInteger)row;

- (void)setHistorySearch:(NSString *)searchString mode:(NSInteger)mode;

@property(readonly) NSMutableArray *items;
@property(readonly) NSView *sourceListControlsView;
@property(readonly) PBGitHistoryController *historyViewController;
@property(readonly) PBGitCommitController *commitViewController;

@end
