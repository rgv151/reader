@implementation Feed : CPObject
{
	int id @accessors;
	CPString name @accessors;
	int order @accessors;
}

- (id)initFromObject:(Object)obj
{
	var self  = [super init];
	if(self)
	{
		[self setId:obj.id];
		[self setName:obj.name];
		[self setOrder:obj.order_id];
	}
	return self
}
@end