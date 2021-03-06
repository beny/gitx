//
//  PBDetailController.m
//  GitX
//
//  Created by Pieter de Bie on 16-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBCommitHookFailedSheet.h"
#import "PBGitCommitController.h"
#import "PBGitHistoryController.h"
#import "PBGitSidebarController.h"
#import "PBGitWindowController.h"
#import "PBGitXMessageSheet.h"
#import "PBGitRepository.h"
#import <ScriptingBridge/ScriptingBridge.h>

@interface TerminalApplication : SBApplication
- (id)doScript:(NSString *)x in:(id)in_;
@end



@implementation PBGitWindowController
@synthesize repository;

- (id)initWithRepository:(PBGitRepository*)theRepository displayDefault:(BOOL)displayDefault {
	self = [self initWithWindowNibName:@"RepositoryWindow"];
    self.repository = theRepository;
	return self;
}

- (void)windowWillClose:(NSNotification *)notification {
    [sidebarController closeView];
    [contentController removeObserver:self forKeyPath:@"status"];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(showCommitView:)) {
		[menuItem setState:(contentController == sidebarController.commitViewController) ? YES : NO];
		return ![repository isBareRepository];
	} else if ([menuItem action] == @selector(showHistoryView:)) {
		[menuItem setState:(contentController != sidebarController.commitViewController) ? YES : NO];
		return ![repository isBareRepository];
	}
	return YES;
}

- (void) awakeFromNib
{
	[[self window] setDelegate:self];
	[[self window] setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
	[[self window] setContentBorderThickness:31.0f forEdge:NSMinYEdge];

	sidebarController = [[PBGitSidebarController alloc] initWithRepository:repository superController:self];
	[[sidebarController view] setFrame:[sourceSplitView bounds]];
	[sourceSplitView addSubview:[sidebarController view]];
	[sourceListControlsView addSubview:sidebarController.sourceListControlsView];

	[[statusField cell] setBackgroundStyle:NSBackgroundStyleRaised];
	[progressIndicator setUsesThreadedAnimation:YES];

	[self showWindow:nil];
}

- (void) removeAllContentSubViews
{
	if ([contentSplitView subviews])
		while ([[contentSplitView subviews] count] > 0)
			[[[contentSplitView subviews] lastObject] removeFromSuperviewWithoutNeedingDisplay];
}

- (void) changeContentController:(PBViewController *)controller
{
	if (!controller || (contentController == controller))
		return;

	if (contentController)
		[contentController removeObserver:self forKeyPath:@"status"];

	[self removeAllContentSubViews];

	contentController = controller;
	
	[[contentController view] setFrame:[contentSplitView bounds]];
	[contentSplitView addSubview:[contentController view]];

	[self setNextResponder: contentController];
	[[self window] makeFirstResponder:[contentController firstResponder]];
	[contentController updateView];
	[contentController addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial context:@"statusChange"];
}

- (void) showCommitView:(id)sender
{
	[sidebarController selectStage];
}

- (void) showHistoryView:(id)sender
{
	[sidebarController selectCurrentBranch];
}

- (void)showCommitHookFailedSheet:(NSString *)messageText infoText:(NSString *)infoText commitController:(PBGitCommitController *)controller
{
	[PBCommitHookFailedSheet beginMessageSheetForWindow:[self window] withMessageText:messageText infoText:infoText commitController:controller];
}

- (void)showMessageSheet:(NSString *)messageText infoText:(NSString *)infoText
{
	[PBGitXMessageSheet beginMessageSheetForWindow:[self window] withMessageText:messageText infoText:infoText];
}

- (void)showErrorSheet:(NSError *)error
{
	if ([[error domain] isEqualToString:PBGitRepositoryErrorDomain])
		[PBGitXMessageSheet beginMessageSheetForWindow:[self window] withError:error];
	else
		[[NSAlert alertWithError:error] beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void)showErrorSheetTitle:(NSString *)title message:(NSString *)message arguments:(NSArray *)arguments output:(NSString *)output
{
	NSString *command = [arguments componentsJoinedByString:@" "];
	NSString *reason = [NSString stringWithFormat:@"%@\n\ncommand: git %@\n%@", message, command, output];
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  title, NSLocalizedDescriptionKey,
							  reason, NSLocalizedRecoverySuggestionErrorKey,
							  nil];
	NSError *error = [NSError errorWithDomain:PBGitRepositoryErrorDomain code:0 userInfo:userInfo];
	[self showErrorSheet:error];
}

- (IBAction)revealInFinder:(id)sender {
	[[NSWorkspace sharedWorkspace] openFile:[repository workingDirectory]];
}

- (IBAction)openInTerminal:(id)sender {
	TerminalApplication *term = [SBApplication applicationWithBundleIdentifier: @"com.apple.Terminal"];
	[term doScript:[NSString stringWithFormat:@"cd \"%@\"; clear; echo '# Opened by GitX:'; git status",
                    [[repository workingDirectory] stringByAppendingString:@"/"]] in:nil];
	[NSThread sleepForTimeInterval:0.1];
	[term activate];
}

- (IBAction)refresh:(id)sender {
	[contentController refresh:self];
}

- (void)updateStatus {
	NSString *status = contentController.status;
	BOOL isBusy = contentController.isBusy;

	if (!status) {
		status = @"";
		isBusy = NO;
	}

	[statusField setStringValue:status];

	if (isBusy) {
		[progressIndicator startAnimation:self];
		[progressIndicator setHidden:NO];
	}
	else {
		[progressIndicator stopAnimation:self];
		[progressIndicator setHidden:YES];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(NSString *)context
{
    if ([context isEqualToString:@"statusChange"]) {
		[self updateStatus];
		return;
	}

	[super observeValueForKeyPath:keyPath ofObject:object change:change context:(__bridge void *)context];
}

- (void)setHistorySearch:(NSString *)searchString mode:(NSInteger)mode
{
	[sidebarController setHistorySearch:searchString mode:mode];
}



#pragma mark -
#pragma mark SplitView Delegates

#define kGitSplitViewMinWidth 150.0f
#define kGitSplitViewMaxWidth 300.0f

#pragma mark min/max widths while moving the divider

- (CGFloat)splitView:(NSSplitView *)view constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex
{
	if (proposedMin < kGitSplitViewMinWidth)
		return kGitSplitViewMinWidth;

	return proposedMin;
}

- (CGFloat)splitView:(NSSplitView *)view constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
	if (dividerIndex == 0)
		return kGitSplitViewMaxWidth;

	return proposedMax;
}

#pragma mark constrain sidebar width while resizing the window

- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSRect newFrame = [sender frame];

	float dividerThickness = [sender dividerThickness];

	NSView *sourceView = [[sender subviews] objectAtIndex:0];
	NSRect sourceFrame = [sourceView frame];
	sourceFrame.size.height = newFrame.size.height;

	NSView *mainView = [[sender subviews] objectAtIndex:1];
	NSRect mainFrame = [mainView frame];
	mainFrame.origin.x = sourceFrame.size.width + dividerThickness;
	mainFrame.size.width = newFrame.size.width - mainFrame.origin.x;
	mainFrame.size.height = newFrame.size.height;

	[sourceView setFrame:sourceFrame];
	[mainView setFrame:mainFrame];
}

@end
