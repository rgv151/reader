@import "CPFaviconView.j"

var CategoryDataViewImage = 1,
    CategoryDataViewText = 2,
    CategoryDataViewBadge = 3;
@implementation CategoryDataView : CPView
{
    CPFaviconView _image;
    CPImageView _folder;
    CPTextField _text;
    CPTextField _badge;
    id _objectValue;
}

- (id)initWithFrame:(CGRect)aFrame
{
    self = [super initWithFrame:aFrame];
    if (self)
    {
        _image = [[CPFaviconView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        [self addSubview:_image];

        _folder = [[CPImageView alloc] initWithFrame:CGRectMake(0, 4, 16, 16)];
        [_folder setImage:[[CPImage alloc] initWithContentsOfFile:@"static/Resources/MonoFolder.png" size:CGSizeMake(16, 16)]];
        [self addSubview:_folder];

        _text = [[CPTextField alloc] initWithFrame:CGRectMake(20.0, 0.0, 130.0, 25.0)];
        [_text setVerticalAlignment:CPCenterVerticalTextAlignment];
        [_text setLineBreakMode:CPLineBreakByTruncatingTail];
        [self addSubview:_text];

        _badge = [[CPTextField alloc] initWithFrame:CGRectMake(195.0, 0.0, 25.0, 25.0)];
        [_badge setVerticalAlignment:CPCenterVerticalTextAlignment];
        [_badge setAlignment:CPCenterTextAlignment];
        [_badge setBackgroundColor:[CPColor colorWithHexString:@"666"]];
        [_badge setTextColor:[CPColor colorWithHexString:@"fff"]];
        _badge._DOMElement.style.borderRadius = "7px";
        [self addSubview:_badge];
    }
    return self;
}

- (void)setStringValue:(CPString)text
{
    [_text setStringValue:text];
}

- (void)setUnread:(int)unread
{
    if (unread != nil && unread != undefined && unread > 0)
    {
        [_badge setStringValue:unread];
        [self showBadge];
    }
    else
    {
        [self hideBadge];
    }
}

- (void)setObjectValue:(id)object
{
    CPLog("CategoryDataView.setObjectValue:%@", object);
    if (_objectValue === object)
        return;

    [[CPNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_ITEM_UNREAD_UPDATED object:_objectValue];

    _objectValue = object;

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(onItemUnreadUpdated:) name:NOTIFICATION_ITEM_UNREAD_UPDATED object:_objectValue];

    if ([_objectValue className] == 'Feed')
    {
        [_image setObjectValue:_objectValue];
        [_folder setHidden:YES];
        [_badge setFrame:CGRectMake(180.0, 0.0, 25.0, 25.0)]
    }
    else
    {
        //[_text setFrame:CGRectMake(0.0, 0.0, 160.0, 25.0)];
        [_image setHidden:YES];
    }
    [self setUnread:[_objectValue unread]];
}

- (void)onItemUnreadUpdated:(CPNotification)notification
{
    var item = [notification object];
    [self setUnread:[item unread]];
}

- (void)showBadge
{
    [_badge setHidden:NO];
}

- (void)hideBadge
{
    [_badge setHidden:YES];
}
@end
