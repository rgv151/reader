@import "../Constants.j"
@import "Feed.j"

@implementation Category : CPObject
{
    int id @accessors;
    CPString name @accessors;
    int order @accessors;
    int parent @accessors;
    int unread @accessors;
    CPMutableArray feeds @accessors;
    CPMutableDictionary _feedMap;

}

- (id)initFromObject:(Object)obj
{
    if (self  = [super init])
    {
        _feedMap = [CPMutableDictionary dictionary];
        [self setId:obj.id];
        [self setName:obj.name];
        [self setOrder:obj.order_id];
        [self setParent:obj.parent_id];
        [self setUnread:obj.unread];

        feeds = [CPMutableArray array];
        if (obj.feeds)
        {
            for (var i = 0; i < obj.feeds.length; i++)
            {
                var uf = [[Feed alloc] initFromObject:obj.feeds[i]];
                [feeds addObject:uf];
                var index = [feeds count] - 1;
                [_feedMap setValue:index forKey:'id_' + [uf id]];
            }
        }
    }
    return self;
}

- (Feed)getFeedById:(int)_id
{
    var index = [_feedMap valueForKey:'id_' + _id];
    return [feeds objectAtIndex:index];
}

- (void)decreaseUnread
{
    [self decreaseUnreadByValue:1];
}

- (void)decreaseUnreadByValue:(int)value
{
    unread-= value;
    [[CPNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_ITEM_UNREAD_UPDATED object:self];
}

@end
