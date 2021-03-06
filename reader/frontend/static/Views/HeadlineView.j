@import <GCKit/GCPopUpButton.j>
@import "../Controllers/HeadlineController.j"
@import "Widgets/HeadlineTableView.j"
@import "Widgets/HeadlineItemView.j"
@import "Widgets/CPFaviconView.j"
@import "../Constants.j"
@import "../LocalSetting.j"

var HeadlineItemViewWidth = 200.0,
    HeadlineItemViewHeight = 100.0;

@implementation HeadlineView : CPView
{
    HeadlineTableView tableView;
    CPPopover filterPopover;

}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    if (self)
    {
        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(onHeadlineLoaded:) name:NOTIFICATION_HEADLINE_LOADED object:nil];
        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserLoggedIn:) name:NOTIFICATION_USER_LOGGED_IN object:nil];

        // init notification register
        [HeadlineController sharedHeadlineController];

        var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth([self bounds]), CGRectGetHeight([self bounds]) - 26.0)];
        [scrollView setAutohidesScrollers:YES];
        [scrollView setHasHorizontalScroller:NO];
        [scrollView setHasVerticalScroller:YES];
        [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
        [scrollView setDelegate:self];

        tableView = [[HeadlineTableView alloc] initWithFrame:[scrollView bounds]];
        [tableView setHeaderView:nil];
        [tableView setCornerView:nil];
        [tableView setBackgroundColor:[CPColor colorWithHexString:@"cccccc"]];
        //[tableView setUsesAlternatingRowBackgroundColors:YES];
        [tableView setRowHeight:HeadlineItemViewHeight];
        [tableView setIntercellSpacing:CGSizeMake(1.0, 1.0)];
        //[tableView setAutoresizingMask:CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin];

        var iconColumn = [[CPTableColumn alloc] initWithIdentifier:@"icon"];
        [[iconColumn headerView] setStringValue:@"Icon"];
        [iconColumn setMinWidth:20];
        [iconColumn setMaxWidth:20];
        [tableView addTableColumn:iconColumn];

        var introColumn = [[CPTableColumn alloc] initWithIdentifier:@"intro"];
        [[introColumn headerView] setStringValue:@"Intro"];
        [introColumn setWidth:CGRectGetWidth([scrollView bounds]) - 40];
        [introColumn setResizingMask:CPTableColumnAutoresizingMask];
        [tableView addTableColumn:introColumn];

        [scrollView setDocumentView:tableView];

        [tableView setDataSource:self];
        [tableView setDelegate:self];

        [self addSubview:scrollView];

        var buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight([self bounds]) - 26.0, CGRectGetWidth([self bounds]), 26.0)];
        [buttonBar setHasResizeControl:NO];
        [buttonBar setResizeControlIsLeftAligned:YES];
        [buttonBar setAutoresizingMask:CPViewWidthSizable | CPViewMinXMargin | CPViewMinYMargin];

        [self addSubview:buttonBar];

        var searchButton = [[CPButton alloc] initWithFrame:CGRectMake(0, 0, 35, 25)];
        [searchButton setBordered:NO];
        [searchButton setToolTip:@"Search"];
        [searchButton setImage:[[CPImage alloc] initWithContentsOfFile:@"static/Resources/search.png" size:CGSizeMake(16, 16)]];
        [searchButton setImagePosition:CPImageOnly];
        [searchButton setAction:@selector(remove:)];
        [searchButton setTarget:self];

        var markAsReadButton = [[CPButton alloc] initWithFrame:CGRectMake(0, 0, 35, 25)];
        [markAsReadButton setBordered:NO];
        [markAsReadButton setToolTip:@"Mark all as read"];
        [markAsReadButton setImage:[[CPImage alloc] initWithContentsOfFile:@"static/Resources/MarkAllAsReadIcon.png" size:CGSizeMake(15, 15)]];
        [markAsReadButton setImagePosition:CPImageOnly];
        [markAsReadButton setAction:@selector(remove:)];
        [markAsReadButton setTarget:self];

        var filterButton = [[GCPopUpButton alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
        [filterButton setImagePosition:CPImageOnly];
        [filterButton addItemWithTitle:@"All"];
        [[filterButton lastItem] setImage:[[CPImage alloc] initWithContentsOfFile:@"static/Resources/MonoAllItems.png" size:CGSizeMake(16, 16)]];
        [filterButton addItemWithTitle:@"Stared"];
        [[filterButton lastItem] setImage:[[CPImage alloc] initWithContentsOfFile:@"static/Resources/MonoStarred.png" size:CGSizeMake(16, 16)]];
        [filterButton addItemWithTitle:@"Unread"];
        [[filterButton lastItem] setImage:[[CPImage alloc] initWithContentsOfFile:@"static/Resources/MonoUnread.png" size:CGSizeMake(16, 16)]];
        [filterButton setValue:CGInsetMake(0, 0, 0, 0) forThemeAttribute:"content-inset"];
        [filterButton setPullsDown:NO];
        [filterButton setSelectedIndex:[LocalSetting get:@"filterMode"] || RSSHeadlineFilterByUnread];
        [filterButton setTarget:self];
        [filterButton setAction:@selector(filterChanged:)];

        var orderButton = [[GCPopUpButton alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
        [orderButton setImagePosition:CPImageOnly];
        [orderButton addItemWithTitle:@""];
        [[orderButton lastItem] setImage:[[CPImage alloc] initWithContentsOfFile:@"static/Resources/sort.png" size:CGSizeMake(16, 16)]];
        [orderButton addItemWithTitle:@"Newest First"];
        [orderButton addItemWithTitle:@"Oldest First"];
        [orderButton addItemWithTitle:@"Title"];
        [orderButton setValue:CGInsetMake(0, 0, 0, 0) forThemeAttribute:"content-inset"];
        [orderButton setPullsDown:YES];
        [orderButton setSelectedIndex:[LocalSetting get:@"orderMode"] || RSSHeadlineOrderByNewestFirst];
        [orderButton setTarget:self];
        [orderButton setAction:@selector(orderChanged:)];
        [orderButton setEnabled:YES];


        [buttonBar setButtons:[searchButton, markAsReadButton, filterButton, orderButton]];

    }
    return self;
}

- (void)filterChanged:(id)sender
{
    var filterMode = [sender selectedIndex];
    [LocalSetting setObject:filterMode forKey:@"filterMode"];
    [[HeadlineController sharedHeadlineController] applyFilters];
}

- (void)orderChanged:(id)sender
{
    var orderMode = [sender selectedIndex];
    [LocalSetting setObject:orderMode forKey:@"orderMode"];
    [[HeadlineController sharedHeadlineController] applyFilters];
}

- (void)onHeadlineLoaded:(CPNotification)notification
{
    CPLog('HeadlineView.onHeadlineLoaded:%@', notification);
    [tableView reloadData];

}

- (void)onUserLoggedIn:(CPNotification)notification
{
    CPLog('HeadlineView.onUserLoggedIn:%@', notification);
    [[HeadlineController sharedHeadlineController] fetchHeadlines];
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return [[HeadlineController sharedHeadlineController] count];
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(int)rowIndex
{
    CPLog('HeadlineView.tableView:%@ objectValueForTableColumn:%@ row:%@', aTableView, aTableColumn, rowIndex);
    [[HeadlineController sharedHeadlineController] prefetchHeadlines:rowIndex];
    return [[HeadlineController sharedHeadlineController] objectAtIndex:rowIndex];
}

- (void)tableView:(CPTableView)aTableView viewForTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
{
    CPLog('HeadlineView.tableView:%@ viewForTableColumn:%@ row:%@', aTableView, aTableColumn, aRow);
    var identifier = [aTableColumn identifier];

    if (identifier == @"multiple")
        identifier = [[[self content] objectAtIndex:aRow] objectForKey:@"identifier"];

    var aView = [aTableView makeViewWithIdentifier:identifier owner:self];

    if (identifier == "intro")
    {
        if (aView == nil)
            aView = [[HeadlineItemView alloc] initWithFrame:CGRectMake(0, 0, HeadlineItemViewWidth, HeadlineItemViewHeight)];
        [aView setRowIndex:aRow];
    }
    else if (identifier == "icon")
    {
        if (aView == nil)
            aView = [[CPFaviconView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    }
    return aView;
}

- (BOOL)tableView:(CPTableView)aTableView shouldSelectRow:(int)rowIndex
{
    CPLog('HeadlineView.tableView:%@ shouldSelectRow:%@', aTableView, rowIndex);
    CPLog("tableView:%@ shouldSelectRow:%@", aTableView, rowIndex);
    var headline = [[HeadlineController sharedHeadlineController] objectAtIndex:rowIndex];
    [headline setUnread:NO];
    [[CPNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_HEADLINE_SELECTED object:headline];
    return YES;
}
@end
