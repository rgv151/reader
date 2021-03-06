@import <AppKit/CPView.j>
@import "../Constants.j"
@import "../Controllers/CategoryController.j"
@import "../Controllers/EntryController.j"
@import "../Controllers/HeadlineController.j"
@import "Widgets/EntryView.j"

@implementation ContentView : CPView
{
   CPButtonBar buttonBar;
   CPView welcomeMessage;
   CPScrollView scrollView;
   EntryView entryView;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(onHeadlineSelected:) name:NOTIFICATION_HEADLINE_SELECTED object:nil];
        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(onEntryLoaded:) name:NOTIFICATION_ENTRY_LOADED object:nil];

        [EntryController sharedEntryController];

        scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth([self bounds]), CGRectGetHeight([self bounds]) - 26.0)];
        [scrollView setAutohidesScrollers:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setBackgroundColor:[CPColor colorWithHexString:"222"]];
        [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [self addSubview:scrollView];

        [self showWelcomeMessage];

        buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight([self bounds]) - 26.0, CGRectGetWidth([self bounds]), 26.0)];
        [buttonBar setHasResizeControl:YES];
        [buttonBar setResizeControlIsLeftAligned:YES];

        [self addSubview:buttonBar];

        var toggleStarredButton = [[CPButton alloc] initWithFrame:CGRectMake(0, 0, 35, 25)];
        [toggleStarredButton setBordered:NO];
        [toggleStarredButton setToolTip:@"Toggle Unread"];
        [toggleStarredButton setImage:[[CPImage alloc] initWithContentsOfFile:@"static/Resources/StarredToolbarIcon.png" size:CGSizeMake(16, 16)]];
        [toggleStarredButton setImagePosition:CPImageOnly];
        [toggleStarredButton setAction:@selector(toggleStarred:)];
        [toggleStarredButton setTarget:self];
        [toggleStarredButton setTag:0];
        [toggleStarredButton setEnabled:YES];

        var toggleUneadButton = [[CPButton alloc] initWithFrame:CGRectMake(0, 0, 35, 25)];
        [toggleUneadButton setBordered:NO];
        [toggleUneadButton setToolTip:@"Toggle Starred"];
        [toggleUneadButton setImage:[[CPImage alloc] initWithContentsOfFile:@"static/Resources/UnreadToolbarIcon.png" size:CGSizeMake(13, 13)]];
        [toggleUneadButton setImagePosition:CPImageOnly];
        [toggleUneadButton setAction:@selector(toggleUnread:)];
        [toggleUneadButton setTarget:self];
        [toggleUneadButton setTag:0];
        [toggleUneadButton setEnabled:YES];

        var shareButton = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0, 0, 35, 25)];
        [shareButton addItemWithTitle:nil];
        [[shareButton lastItem] setImage:[[CPImage alloc] initWithContentsOfFile:@"static/Resources/share.png" size:CGSizeMake(16, 13)]];
        [shareButton setImagePosition:CPImageOnly];
        [shareButton setValue:CGInsetMake(0, 0, 0, 0) forThemeAttribute:"content-inset"];
        [shareButton setPullsDown:YES];
        [shareButton setTarget:self];
        [shareButton setEnabled:YES];
        [shareButton addItemsWithTitles: [CPArray arrayWithObjects:
                    @"Facebook",
                    @"Twitter",
                    nil]
        ];

        var fullscreenButton = [[CPButton alloc] initWithFrame:CGRectMake(0, 0, 35, 25)];
        [fullscreenButton setBordered:NO];
        [fullscreenButton setImage:[[CPImage alloc] initWithContentsOfFile:@"static/Resources/fullscreen.png" size:CGSizeMake(16, 16)]];
        [fullscreenButton setImagePosition:CPImageOnly];
        [fullscreenButton setAction:@selector(toggleFullscreenMode:)];
        [fullscreenButton setTarget:self];
        [fullscreenButton setEnabled:YES];

        [buttonBar setButtons:[fullscreenButton, toggleStarredButton, toggleUneadButton, shareButton]];
        [buttonBar setAutoresizingMask:CPViewWidthSizable | CPViewMinXMargin | CPViewMinYMargin];

    }

    return self;
}

- (void)onHeadlineSelected:(CPNotification)notification
{
    CPLog('onHeadlineSelected:%@', notification);
    var headline = [notification object];
    [[EntryController sharedEntryController] loadEntry:[headline id]];
}

- (void)onEntryLoaded:(CPNotification)notification
{
    CPLog('onEntryLoaded:%@', notification);
    var entryId = [notification object];

    [self showEntryView];
    var entry = [[EntryController sharedEntryController] getCachedEntryWithId:entryId];
    [entryView setEntry:entry];

    if ([entry unread] == YES)
    {
        [entry setUnread:NO];

        var category = [[CategoryController sharedCategoryController] getCategoryById:[entry category]],
            feed = [category getFeedById:[entry feed]];
        [category decreaseUnread];
        [feed decreaseUnread];
        [[EntryController sharedEntryController] markAsRead:[entry id]];
    }
}

- (void)showWelcomeMessage
{
    if (!welcomeMessage)
    {
        welcomeMessage = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth([self bounds]), CGRectGetHeight([self bounds]) - 26)];
        [welcomeMessage setBackgroundColor:[CPColor colorWithHexString:"222"]];
        [welcomeMessage setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [self addSubview:welcomeMessage];

        var first = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, CGRectGetHeight([welcomeMessage bounds]) / 2 - 50, CGRectGetWidth([welcomeMessage bounds]), 200.0)];
        [first setStringValue:@"Welcome to Doda Reader"];
        [first setAutoresizingMask:CPViewWidthSizable | CPViewMaxXMargin | CPViewMinYMargin];
        [first setFont:[CPFont boldFontWithName:'Titillium Web' size:36 italic:YES]];
        [first setTextColor:[CPColor colorWithHexString:@"333"]];
        [first setTextShadowColor:[CPColor colorWithHexString:@"000"]];
        [first setTextShadowOffset:CGSizeMake(0.0, 1.0)];
        [first setAlignment:CPCenterTextAlignment];
        [welcomeMessage addSubview:first];

        var second = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, CGRectGetHeight([welcomeMessage bounds]) / 2, CGRectGetWidth([welcomeMessage bounds]), 200.0)];
        [second setStringValue:@"Please select an article to continue"];
        [second setAutoresizingMask:CPViewWidthSizable | CPViewMinXMargin | CPViewMinYMargin];
        [second setFont:[CPFont boldFontWithName:'Open Sans' size:16]];
        [second setTextColor:[CPColor colorWithHexString:@"333"]];
        [second setTextShadowColor:[CPColor colorWithHexString:@"000"]];
        [second setTextShadowOffset:CGSizeMake(1.0, 1.0)];
        [second setAlignment:CPCenterTextAlignment];
        [welcomeMessage addSubview:second];
    }
    [scrollView setHidden:YES];
    [welcomeMessage setHidden:NO];
}

- (void)showEntryView
{
    if (!entryView)
    {
        entryView = [[EntryView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth([self bounds]), CGRectGetHeight([self bounds]) - 26)];
        [entryView setBackgroundColor:[CPColor colorWithHexString:"222"]];
        [entryView setAutoresizingMask:CPViewWidthSizable];
        //[self addSubview:entryView];
        [scrollView setDocumentView:entryView];
    }
    [scrollView setHidden:NO];
    [welcomeMessage setHidden:YES];
}

- (CPButtonBar)getButtonBar
{
    return buttonBar;
}

- (void)toggleFullscreenMode:(id)sender
{
    [entryView enterFullScreenMode];
}

- (void)toggleUnread:(id)sender
{
    if ([sender tag] == 0)
    {
        [sender setImage:[[CPImage alloc] initWithContentsOfFile:@"static/Resources/UnreadToolbarIconActive.png" size:CGSizeMake(13, 13)]];
        [sender setTag:1];
    }
    else
    {
        [sender setImage:[[CPImage alloc] initWithContentsOfFile:@"static/Resources/UnreadToolbarIcon.png" size:CGSizeMake(13, 13)]];
        [sender setTag:0];
    }

}

- (void)toggleStarred:(id)sender
{
    if ([sender tag] == 0)
    {
        [sender setImage:[[CPImage alloc] initWithContentsOfFile:@"static/Resources/StarredToolbarIconActive.png" size:CGSizeMake(16, 16)]];
        [sender setTag:1];
    }
    else
    {
        [sender setImage:[[CPImage alloc] initWithContentsOfFile:@"static/Resources/StarredToolbarIcon.png" size:CGSizeMake(16, 16)]];
        [sender setTag:0];
    }

}
@end
