/** GSWDisplayGroup.m - <title>GSWeb: Class GSWDisplayGroup</title>

   Copyright (C) 1999-2002 Free Software Foundation, Inc.
   
   Written by:	Manuel Guesdon <mguesdon@orange-concept.com>
                Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: 	Jan 1999
   
   $Revision$
   $Date$
   $Id$

   This file is part of the GNUstep Web Library.
   
   <license>
   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
   </license>
**/

#include "GSWeb.h"
@class EOUndoManager;

//====================================================================
@implementation GSWDisplayGroup

#if GDL2 // GDL2 implementation

//--------------------------------------------------------------------
//	init

- init
{
  if ((self = [super init]))
    {
      _allObjects = [[NSMutableArray alloc] initWithCapacity:16];
      _displayedObjects = [[NSMutableArray alloc] initWithCapacity:16];
      _selectedObjects = [[NSMutableArray alloc] initWithCapacity:8];

      _queryMatch    = [[NSMutableDictionary alloc] initWithCapacity:8];
      _queryMin      = [[NSMutableDictionary alloc] initWithCapacity:8];
      _queryMax      = [[NSMutableDictionary alloc] initWithCapacity:8];
      NSDebugMLLog(@"gswdisplaygroup",@"_queryOperator=%@",_queryOperator);
      _queryOperator = [[NSMutableDictionary alloc] initWithCapacity:8];
      NSDebugMLLog(@"gswdisplaygroup",@"_queryOperator=%@",_queryOperator);

      _queryBindings = [[NSMutableDictionary alloc] initWithCapacity:8];

      //  _selection = 1; //????
      _batchIndex = 1;

      [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(_changedInEditingContext:)
        name:EOObjectsChangedInEditingContextNotification
        object:nil];

      [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(_invalidatedAllObjectsInStore:)
        name:EOInvalidatedAllObjectsInStoreNotification
        object:nil];

      //_selection=NSArray * object:0xf78b80 Description:()
      //_insertedObjectDefaultValues=NSDictionary * object:0xf78b60 Description:{}
      ASSIGN(_defaultStringMatchOperator,@"caseInsensitiveLike");
      ASSIGN(_defaultStringMatchFormat,@"%@");

      [self setSelectsFirstObjectAfterFetch:YES];
    };
  return self;
};

-(id)initWithKeyValueUnarchiver:(EOKeyValueUnarchiver*)unarchiver
{
/*
Description: <EOKeyValueUnarchiver: 0x1a84d20>
  --[1] Dumping object 0x1a84d20 of Class EOKeyValueUnarchiver
  _propertyList=NSDictionary * object:0x1057850 Description:{
    class = WODisplayGroup; 
    dataSource = {
        class = EODatabaseDataSource; 
        editingContext = session.defaultEditingContext; 
        fetchSpecification = {class = EOFetchSpecification; entityName = MovieMedia; isDeep = YES; }; 
    }; 
    formatForLikeQualifier = "%@*"; 
    _numberOfObjectsPerBatch = 10; 
    selectsFirstObjectAfterFetch = YES; 
}
  _parent=id object:0x0 Description:*nil*
  _nextParent=id object:0x0 Description:*nil*
  _allUnarchivedObjects=NSMutableArray * object:0x1a85920 Description:()
  _delegate=id object:0x1a84ff0 Description:<WOBundleUnarchiverDelegate: 0x1a84ff0>
  _awakenedObjects=struct ? {...} * PTR
  isa=Class Class:EOKeyValueUnarchiver

*/
  if ((self=[self init]))
    {
      LOGObjectFnStart();
      NSDebugMLLog(@"gswdisplaygroup",@"GSWDisplayGroup %p",self);
      [self setNumberOfObjectsPerBatch:
              [unarchiver decodeIntForKey:@"numberOfObjectsPerBatch"]];
      [self setFetchesOnLoad:
              [unarchiver decodeBoolForKey:@"fetchesOnLoad"]];
      [self setValidatesChangesImmediately:
              [unarchiver decodeBoolForKey:@"validatesChangesImmediately"]];
      [self setSelectsFirstObjectAfterFetch:
              [unarchiver decodeBoolForKey:@"selectsFirstObjectAfterFetch"]];
      [self setLocalKeys:
              [unarchiver decodeObjectForKey:@"localKeys"]];
      //Don't call setDataSource: because we're not ready !
      ASSIGN(_dataSource,[unarchiver decodeObjectForKey:@"dataSource"]);        
      [self setSortOrderings:
              [unarchiver decodeObjectForKey:@"sortOrdering"]];
      [self setQualifier:
              [unarchiver decodeObjectForKey:@"qualifier"]];
      [self setDefaultStringMatchFormat:
              [unarchiver decodeObjectForKey:@"defaultStringMatchFormat"]];
      [self setInsertedObjectDefaultValues:
              [unarchiver decodeObjectForKey:@"insertedObjectDefaultValues"]];
      [self setQueryOperator:[unarchiver decodeObjectForKey:@"queryOperator"]];
      [self finishInitialization];
      NSDebugMLLog(@"gswdisplaygroup",@"GSWDisplayGroup %p : %@",self,self);
      LOGObjectFnStop();
    };
  return self;
};

-(NSString*)description
{
  NSString* dscr=nil;
  GSWLogAssertGood(self);
  NSDebugMLLog(@"gswdisplaygroup",@"GSWDisplayGroup description Self=%p",self);
  dscr=[NSString stringWithFormat:@"<%s %p - \n",
                  object_get_class_name(self),
                  (void*)self];

  dscr=[dscr stringByAppendingFormat:@"numberOfObjectsPerBatch:[%d]\n",
               _numberOfObjectsPerBatch];
  dscr=[dscr stringByAppendingFormat:@"fetchesOnLoad:[%s]\n",
               _flags.autoFetch ? "YES" : "NO"];
  dscr=[dscr stringByAppendingFormat:@"validatesChangesImmediately:[%s]\n",
               _flags.validateImmediately ? "YES" : "NO"];
  dscr=[dscr stringByAppendingFormat:@"selectsFirstObjectAfterFetch:[%s]\n",
               _flags.selectFirstObject ? "YES" : "NO"];
  dscr=[dscr stringByAppendingFormat:@"localKeys:[%@]\n",
               _localKeys];
  dscr=[dscr stringByAppendingFormat:@"dataSource:[%@]\n",
               _dataSource];
  dscr=[dscr stringByAppendingFormat:@"sortOrdering:[%@]\n",
               _sortOrdering];
  dscr=[dscr stringByAppendingFormat:@"qualifier:[%@]\n",
               _qualifier];
  dscr=[dscr stringByAppendingFormat:@"formatForLikeQualifier:[%@]\n",
               _defaultStringMatchFormat];
  dscr=[dscr stringByAppendingFormat:@"insertedObjectDefaultValues:[%@]\n",
               _insertedObjectDefaultValues];
  dscr=[dscr stringByAppendingFormat:@"queryOperator:[%@]\n",
               _queryOperator];
  dscr=[dscr stringByAppendingFormat:@"queryMatch:[%@]\n",
               _queryMatch];
  dscr=[dscr stringByAppendingFormat:@"queryMin:[%@]\n",
               _queryMin];
  dscr=[dscr stringByAppendingFormat:@"queryMax:[%@]\n",
               _queryMax];
  dscr=[dscr stringByAppendingFormat:@"queryOperator:[%@]\n",
               _queryOperator];
  dscr=[dscr stringByAppendingFormat:@"defaultStringMatchOperator:[%@]\n",
               _defaultStringMatchOperator];
  dscr=[dscr stringByAppendingFormat:@"defaultStringMatchFormat:[%@]\n",
               _defaultStringMatchFormat];
  dscr=[dscr stringByAppendingFormat:@"queryBindings:[%@]\n",
               _queryBindings];
  dscr=[dscr stringByAppendingString:@">"];
  return dscr;
};


-(void)awakeFromKeyValueUnarchiver:(EOKeyValueUnarchiver*)unarchiver
{
  LOGObjectFnStart();
  if (_dataSource)
    [unarchiver ensureObjectAwake:_dataSource];
  if ([self fetchesOnLoad])
    {
      NSLog(@"***** awakeFromKeyValueUnarchiver in GSWDisplayGroup is called *****");
      [self fetch];
      //      [self fetch];//?? NO: fetch "each time it is loaded in web browser"
    };
  LOGObjectFnStop();
};


-(void)finishInitialization
{
  LOGObjectFnStart();
  [self _setUpForNewDataSource];
  //Finished ?

  LOGObjectFnStop();
};

-(void)_setUpForNewDataSource
{
  LOGObjectFnStart();
  // call [_dataSource editingContext];
  //Finished ?
  LOGObjectFnStop();
};
	
-(void)encodeWithKeyValueArchiver:(id)object_
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
};

-(void)_presentAlertWithTitle:(id)title
                      message:(id)msg
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
};

-(void)_addQualifiersToArray:(NSMutableArray*)array
                   forValues:(NSDictionary*)values
            operatorSelector:(SEL)sel
{
  //OK
  NSEnumerator *enumerator=nil;
  NSString *key=nil;
  NSString *op=nil;
  LOGObjectFnStart();
  NSDebugMLLog(@"gswdisplaygroup",@"array=%@",array);
  NSDebugMLLog(@"gswdisplaygroup",@"values=%@",values);
  NSDebugMLLog(@"gswdisplaygroup",@"operatorSelector=%p: %@",
               (void*)sel,
               NSStringFromSelector(sel));
  enumerator = [values keyEnumerator];
  while((key = [enumerator nextObject]))
    {
      EOQualifier* qualifier=nil;
      id value=[values objectForKey:key];
      NSDebugMLLog(@"gswdisplaygroup",@"key=%@ value=%@",key,value);
      qualifier=[self _qualifierForKey:key
                      value:value
                      operatorSelector:sel];
      NSDebugMLLog(@"gswdisplaygroup",@"qualifier=%@",qualifier);
      if (qualifier)
        [array addObject:qualifier];
    };
  NSDebugMLLog(@"gswdisplaygroup",@"array=%@",array);
  LOGObjectFnStop();
};

-(EOQualifier*)_qualifierForKey:(id)key
                          value:(id)value
               operatorSelector:(SEL)sel
{
  //near OK (see VERIFY)
  EOClassDescription* cd=nil;
  EOQualifier* qualifier=nil;
  NSException* validateException=nil;
  LOGObjectFnStart();
  NSDebugMLLog(@"gswdisplaygroup",@"value=%@",value);
  NSDebugMLLog(@"gswdisplaygroup",@"operatorSelector=%p: %@",
               (void*)sel,
               NSStringFromSelector(sel));
  cd=[_dataSource classDescriptionForObjects];// //ret [EOEntityClassDescription]: <EOEntityClassDescription: 0x1a3c7b0>
  validateException=[cd validateValue:value
                        forKey:key];
  NSDebugMLLog(@"gswdisplaygroup",@"validateException=%@",validateException);
  if (validateException)
    {
      [validateException raise]; //VERIFY
    }
  else
    {
      NSString* op=nil;
      NSString* fvalue=value;
      
      //VERIFY!!
      NSDebugMLLog(@"gswdisplaygroup",@"_queryOperator=%@",_queryOperator);
      op = [_queryOperator objectForKey:key];
      NSDebugMLLog(@"gswdisplaygroup",@"op=%@",op);
      if(op)
	sel = [EOQualifier operatorSelectorForString:op];
      NSDebugMLLog(@"gswdisplaygroup",@"operatorSelector=%p: %@",
                   (void*)sel,
                   NSStringFromSelector(sel));

      NSDebugMLLog(@"gswdisplaygroup",@"_defaultStringMatchFormat=%@",_defaultStringMatchFormat);

      if (_defaultStringMatchFormat)
        fvalue=[NSString stringWithFormat:_defaultStringMatchFormat,
                         value];//VERIFY !!!      
      NSDebugMLLog(@"gswdisplaygroup",@"fvalue=%@",fvalue);
      qualifier=[[[EOKeyValueQualifier alloc]
                   initWithKey:key
                   operatorSelector:sel
                   value:fvalue] autorelease];
    };
  NSDebugMLLog(@"gswdisplaygroup",@"qualifier=%@",qualifier);
  return qualifier;
};

-(BOOL)_deleteObjectsAtIndexes:(id)indexes
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
  return NO;
};


-(BOOL)_deleteObject:(id)object
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
  return NO;
};

-(int)_selectionIndex
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
  return 0;
};


-(void)_lastObserverNotified:(id)object
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
};


-(void)_beginObserverNotification:(id)object
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
};

-(void)_notifySelectionChanged
{
  LOGObjectFnStart();
  [EOObserverCenter notifyObserversObjectWillChange:nil];//OK ?
  LOGObjectFnStop();
};



-(void)_notifyRowChanged:(int)row
{
  LOGObjectFnStart();
//-1 ==> nil ?
  [EOObserverCenter notifyObserversObjectWillChange:nil]; //VERIFY
  LOGObjectFnStop();
};



-(id)_notify:(SEL)selector
        with:(id)object1
        with:(id)object2

{
  LOGObjectFnStart();
  //TODOFN
  if (selector==@selector(displayGroup:didFetchObjects:)) //TODO ????
    {
      //Do it on object1
      if(_delegateRespondsTo.didFetchObjects)
        [_delegate displayGroup:object1
                   didFetchObjects:object2];
    }
  else
    {
      LOGObjectFnNotImplemented();	//TODOFN
    };
  LOGObjectFnStop();
  return self; //??
};


-(id)_notify:(SEL)selector
        with:(id)object
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
  return nil;
};


-(EOUndoManager*)undoManager
{
  EOUndoManager* undoManager=nil;
  LOGObjectFnStart();
  undoManager=[[_dataSource editingContext] undoManager];
  LOGObjectFnStop();
  return undoManager;
};

-(void)objectsInvalidatedInEditingContext:(id)object_
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
};


-(void)objectsChangedInEditingContext:(id)object
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
};


-(void)_changedInEditingContext:(NSNotification *)notification
{
  BOOL redisplay = YES;
  LOGObjectFnStart();

  if(_delegateRespondsTo.shouldRedisplay == YES)
    redisplay = [_delegate displayGroup:self
		      shouldRedisplayForEditingContextChangeNotification:notification];

  if(redisplay == YES)
    [self redisplay];
  LOGObjectFnStop();
}

-(void)_invalidatedAllObjectsInStore:(NSNotification *)notification
{
  BOOL refetch = YES;
  LOGObjectFnStart();

  if(_delegateRespondsTo.shouldRefetchObjects == YES)
    refetch = [_delegate displayGroup:self
		    shouldRefetchForInvalidatedAllObjectsNotification:
		      notification];

  if(refetch == YES)
    [self fetch];
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  _delegate = nil;

  DESTROY(_dataSource);

  DESTROY(_allObjects);
  DESTROY(_displayedObjects);
  DESTROY(_selection);
  DESTROY(_selectedObjects);
  DESTROY(_sortOrdering);
  DESTROY(_qualifier);
  DESTROY(_localKeys);

  DESTROY(_insertedObjectDefaultValues);
  DESTROY(_savedAllObjects);

  DESTROY(_queryMatch);
  DESTROY(_queryMin);
  DESTROY(_queryMax);
  DESTROY(_queryOperator);

  DESTROY(_defaultStringMatchOperator);
  DESTROY(_defaultStringMatchFormat);

  DESTROY(_queryBindings);

  [super dealloc];
}

//--------------------------------------------------------------------
//	allObjects

- (NSArray *)allObjects
{
  return _allObjects;
}

//--------------------------------------------------------------------
//	allQualifierOperators

- (NSArray *)allQualifierOperators
{
  return [EOQualifier allQualifierOperators];
}

//--------------------------------------------------------------------
//	batchCount

- (unsigned)batchCount
{
  unsigned batchCount=0;
  unsigned count=0;
  LOGObjectFnStart();

  if(!_numberOfObjectsPerBatch)
    batchCount=1;
  else
    {
      count = [_allObjects count];
      if(!count)
        batchCount=1;
      else
        batchCount=(count / _numberOfObjectsPerBatch) +
          (count % _numberOfObjectsPerBatch ? 1 : 0);
    };
  LOGObjectFnStop();
  return batchCount;
}

//--------------------------------------------------------------------
//	buildsQualifierFromInput

-(BOOL)buildsQualifierFromInput
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
  return NO;
};

//--------------------------------------------------------------------
//	clearSelection

- (BOOL)clearSelection
{
  BOOL result=NO;
  LOGObjectFnStart();
  result=[self setSelectionIndexes:[NSArray array]];
  LOGObjectFnStop();
  return result;
}

//--------------------------------------------------------------------
//	currentBatchIndex

- (unsigned)currentBatchIndex
{
  return _batchIndex;
}

//--------------------------------------------------------------------
//	dataSource

- (EODataSource *)dataSource
{
  return _dataSource;
}

//--------------------------------------------------------------------
//	setDataSource:

- (void)setDataSource:(EODataSource *)dataSource
{
  EOEditingContext *context=nil;
  LOGObjectFnStart();

  if(_dataSource)
    {
      context = [_dataSource editingContext];
      [context removeEditor:self];
      if([self isEqual:[context messageHandler]] == YES)
	[context setMessageHandler:nil];
    }

  ASSIGN(_dataSource,dataSource);

  context = [_dataSource editingContext];
  [context addEditor:self];
  if([context messageHandler] == nil)
    [context setMessageHandler:self];

  [_displayedObjects removeAllObjects];

  if(_delegateRespondsTo.didChangeDataSource == YES)
    [_delegate displayGroupDidChangeDataSource:self];
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	defaultStringMatchFormat

- (NSString *)defaultStringMatchFormat
{
  return _defaultStringMatchFormat;
}

//--------------------------------------------------------------------
//	defaultStringMatchOperator

- (NSString *)defaultStringMatchOperator
{
  return _defaultStringMatchOperator;
}

//--------------------------------------------------------------------
//	delegate

- (id)delegate
{
  return _delegate;
}

//--------------------------------------------------------------------
//	setDelegate:

- (void)setDelegate:(id)delegate
{
  LOGObjectFnStart();
  _delegate = delegate;

  _delegateRespondsTo.createObjectFailed = 
    [_delegate respondsToSelector:@selector(displayGroup:createObjectFailedForDataSource:)];
  _delegateRespondsTo.didDeleteObject = 
    [_delegate respondsToSelector:@selector(displayGroup:didDeleteObject:)];
  _delegateRespondsTo.didFetchObjects = 
    [_delegate respondsToSelector:@selector(displayGroup:didFetchObjects:)];
  _delegateRespondsTo.didInsertObject = 
    [_delegate respondsToSelector:@selector(displayGroup:didInsertObject:)];
  _delegateRespondsTo.didSetValueForObject = 
    [_delegate respondsToSelector:@selector(displayGroup:didSetValue:forObject:key:)];
  _delegateRespondsTo.displayArrayForObjects = 
    [_delegate respondsToSelector:@selector(displayGroup:displayArrayForObjects:)];
  _delegateRespondsTo.shouldChangeSelection = 
    [_delegate respondsToSelector:@selector(displayGroup:shouldChangeSelectionToIndexes:)];
  _delegateRespondsTo.shouldInsertObject = 
    [_delegate respondsToSelector:@selector(displayGroup:shouldInsertObject:atIndex:)];
  _delegateRespondsTo.shouldDeleteObject = 
    [_delegate respondsToSelector:@selector(displayGroup:shouldDeleteObject:)];
  _delegateRespondsTo.shouldRedisplay = 
    [_delegate respondsToSelector:@selector(displayGroup:shouldRedisplayForEditingContextChangeNotification:)];
  _delegateRespondsTo.shouldRefetchObjects = 
    [_delegate respondsToSelector:@selector(displayGroup:shouldRefetchForInvalidatedAllObjectsNotification:)];
  _delegateRespondsTo.didChangeDataSource = 
    [_delegate respondsToSelector:@selector(displayGroupDidChangeDataSource:)];
  _delegateRespondsTo.didChangeSelectedObjects = 
    [_delegate respondsToSelector:@selector(displayGroupDidChangeSelectedObjects:)];
  _delegateRespondsTo.didChangeSelection = 
    [_delegate respondsToSelector:@selector(displayGroupDidChangeSelection:)];
  _delegateRespondsTo.shouldFetchObjects = 
    [_delegate respondsToSelector:@selector(displayGroupShouldFetch:)];
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	delete

- (id)delete
{
  LOGObjectFnStart();
  [self deleteSelection];
  LOGObjectFnStop();
  return nil;//return nil for direct .gswd actions ==> same page
}

//--------------------------------------------------------------------
//	deleteObjectAtIndex:

- (BOOL)deleteObjectAtIndex:(unsigned)index
{
  BOOL delete = YES;
  id object=nil;
  LOGObjectFnStart();

  object = [_allObjects objectAtIndex:index];

  if(_delegateRespondsTo.shouldDeleteObject == YES)
    delete = [_delegate displayGroup:self  shouldDeleteObject:object];

  if(delete)
    {
      NS_DURING
        {
          [_dataSource deleteObject:object];
          
          [_displayedObjects removeObjectIdenticalTo:object];
          [_allObjects removeObjectIdenticalTo:object];
          
          if(_delegateRespondsTo.didDeleteObject == YES)
            [_delegate displayGroup:self  didDeleteObject:object];
        }
      NS_HANDLER
        {
          NSLog(@"GSWDisplayGroup (deleteObjectAtIndex:) Can't delete object at index : %d", index);
          NSLog(@"object : %@", object);
          NSLog(@"Exception :  %@ %@ Name:%@ Reason:%@\n",
                localException,
                [localException description],
                [localException name],
                [localException reason]);
          delete = NO;
        }
      NS_ENDHANDLER;
    };
  
  [self clearSelection];

  LOGObjectFnStop();
  return delete;
}

//--------------------------------------------------------------------
//	deleteSelection

- (BOOL)deleteSelection
{
  BOOL result=YES;
  BOOL delete = YES;
  NSEnumerator *enumerator=nil;
  id object=nil;
  LOGObjectFnStart();

  enumerator = [_selectedObjects objectEnumerator];
  while((object = [enumerator nextObject]))
    {
      if(_delegateRespondsTo.shouldDeleteObject == YES)
	delete = [_delegate displayGroup:self
			   shouldDeleteObject:object];

      if(delete == NO)
	result=NO;
    }
  if (result)
    {
      NS_DURING
        {
          enumerator = [_selectedObjects objectEnumerator];
          while((object = [enumerator nextObject]))
            {
              [_dataSource deleteObject:object];
              
              [_displayedObjects removeObjectIdenticalTo:object];
              [_allObjects removeObjectIdenticalTo:object];
              
              if(_delegateRespondsTo.didDeleteObject == YES)
                [_delegate displayGroup:self
                          didDeleteObject:object];
            }
        }
      NS_HANDLER
        {
          NSLog(@"GSWDisplayGroup (deleteSelection:) Can't delete object");
          NSLog(@"object : %@", object);
          NSLog(@"Exception :  %@ %@ Name:%@ Reason:%@\n",
                localException,
                [localException description],
                [localException name],
                [localException reason]);
          delete = NO;
        }
      NS_ENDHANDLER;
    };

  [self clearSelection];

  LOGObjectFnStop();
  return result;
}

//--------------------------------------------------------------------
//	detailKey

- (NSString *)detailKey
{
  NSString* detailKey=nil;
  LOGObjectFnStart();

  if([self hasDetailDataSource] == YES)
    detailKey= [(EODetailDataSource *)_dataSource detailKey];

  LOGObjectFnStop();
  return detailKey;
}

//--------------------------------------------------------------------
//	displayBatchContainingSelectedObject

-(id)displayBatchContainingSelectedObject
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
  return nil;
};

//--------------------------------------------------------------------
//	displayedObjects

- (NSArray *)displayedObjects
{
  //OK
  return _displayedObjects;
}

//--------------------------------------------------------------------
//	displayNextBatch

- (id)displayNextBatch
{
  int count = [_allObjects count];
  NSRange range;
  LOGObjectFnStart();

  [_displayedObjects removeAllObjects];

  if(!_numberOfObjectsPerBatch || count <= _numberOfObjectsPerBatch)
    {
      _batchIndex = 1;
      [_displayedObjects addObjectsFromArray:_allObjects];
    }
  else
    {
      if(_batchIndex >= [self batchCount])
	{
	  _batchIndex = 1;
	  range.location = 0;
	  range.length = _numberOfObjectsPerBatch;
	}
      else
	{
	  range.location = _batchIndex * _numberOfObjectsPerBatch;
	  range.length = (range.location + _numberOfObjectsPerBatch > count ?
			  count - range.location : _numberOfObjectsPerBatch);
	  _batchIndex++;
	}

      [_displayedObjects addObjectsFromArray:[_allObjects
					      subarrayWithRange:range]];
    }

  [self clearSelection];

  LOGObjectFnStop();
  return nil;//return nil for direct .gswd actions ==> same page
}

//--------------------------------------------------------------------
//	displayPreviousBatch

- (id)displayPreviousBatch
{
  int count = [_allObjects count];
  NSRange range;
  LOGObjectFnStart();

  [_displayedObjects removeAllObjects];

  if(!_numberOfObjectsPerBatch || count <= _numberOfObjectsPerBatch)
    {
      _batchIndex = 1;
      [_displayedObjects addObjectsFromArray:_allObjects];
    }
  else
    {
      if(_batchIndex == 1)
	{
	  _batchIndex = [self batchCount];
	  range.location = (_batchIndex-1) * _numberOfObjectsPerBatch;

	  range.length = (range.location + _numberOfObjectsPerBatch > count ?
			  count - range.location : _numberOfObjectsPerBatch);
	}
      else
	{
	  _batchIndex--;
	  range.location = (_batchIndex-1) *  _numberOfObjectsPerBatch;
	  range.length = _numberOfObjectsPerBatch;
	}

      [_displayedObjects addObjectsFromArray:[_allObjects
					      subarrayWithRange:range]];
    }

  [self clearSelection];

  LOGObjectFnStop();
  return nil;//return nil for direct .gswd actions ==> same page
}

//--------------------------------------------------------------------
//	endEditing

- (BOOL)endEditing
{
  return YES;
}

//--------------------------------------------------------------------
//	executeQuery

-(id)executeQuery
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
  return nil;//return nil for direct .gswd actions ==> same page
};

//--------------------------------------------------------------------
//	fetch

- (id)fetch
  //Near OK
{
  BOOL fetch = YES;
  EOUndoManager* undoManager=nil;
  LOGObjectFnStart();
  //[self endEditing];//WO45P3 ret 1 //TODO if NO ?
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:@"WODisplayGroupWillFetch" //TODO Name
    object:self];
  undoManager=[self undoManager];
  [undoManager removeAllActionsWithTarget:self];
  [_dataSource setQualifierBindings:_queryBindings];

  if(_delegateRespondsTo.shouldFetchObjects == YES)
    fetch = [_delegate displayGroupShouldFetch:self];

  if(fetch)
    {
      NSArray *objects=nil;

      objects = [_dataSource fetchObjects];
      [self setObjectArray:objects];//OK
      [self _notify:@selector(displayGroup:didFetchObjects:)
            with:self
            with:_allObjects];
      /*IN  setObjectArray:     // selection
        if ([self selectsFirstObjectAfterFetch] == YES) {
        [self setCurrentBatchIndex:1];
      */
    };
  LOGObjectFnStop();
  return nil;//return nil for direct .gswd actions ==> same page
}

//--------------------------------------------------------------------
//	fetchesOnLoad

- (BOOL)fetchesOnLoad
{
  return _flags.autoFetch;
}

//--------------------------------------------------------------------
//	hasDetailDataSource

- (BOOL)hasDetailDataSource
{
  return [_dataSource isKindOfClass:[EODetailDataSource class]];
}

//--------------------------------------------------------------------
/** returns YES if the displayGroup paginates display (batchCount>1), false otherwise **/

- (BOOL)hasMultipleBatches
{
  //return !_flags.fetchAll;
  return ([self batchCount]>1);
}

//--------------------------------------------------------------------
//	inputObjectForQualifier

-(NSMutableDictionary*)inputObjectForQualifier
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
  return nil;
};

//--------------------------------------------------------------------
//	indexOfFirstDisplayedObject;

- (unsigned)indexOfFirstDisplayedObject
{
  int indexOfFirstDisplayedObject=0;
  int batch = 0;
  LOGObjectFnStart();

  batch=[self currentBatchIndex];
  indexOfFirstDisplayedObject=((batch-1) * _numberOfObjectsPerBatch);

  LOGObjectFnStop();
  return indexOfFirstDisplayedObject;
}

//--------------------------------------------------------------------
//	indexOfLastDisplayedObject;

- (unsigned)indexOfLastDisplayedObject
{
  int indexOfLastDisplayedObject=0;
  int batch = 0;
  LOGObjectFnStart();
  batch=[self currentBatchIndex];

  indexOfLastDisplayedObject=((batch-1) * _numberOfObjectsPerBatch) + [_displayedObjects count];
  LOGObjectFnStop();
  return indexOfLastDisplayedObject;
}

//--------------------------------------------------------------------
//	inQueryMode

- (BOOL)inQueryMode
{
  return _flags.queryMode;
}

//--------------------------------------------------------------------
-(void)editingContext:(id)editingContext
  presentErrorMessage:(id)msg
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
};

//--------------------------------------------------------------------
//	insert

- (id)insert
{
  unsigned index=0, count=0;
  LOGObjectFnStart();
  count = [_allObjects count];

  if([_selection count])
    index = [[_selection objectAtIndex:0] unsignedIntValue]+1;

  index=max(0,index);
  index=min(count,index);

  NSDebugMLog(@"INSERT Index=%d",index);
  [self insertObjectAtIndex:index];

  LOGObjectFnStop();
  return nil;//return nil for direct .gswd actions ==> same page
}

//--------------------------------------------------------------------

- (id)insertAfterLastObject
{
  int index= [_allObjects count];
  return [self insertObjectAtIndex:index];
}

//--------------------------------------------------------------------
//	insertedObjectDefaultValues

- (NSDictionary *)insertedObjectDefaultValues
{
  return _insertedObjectDefaultValues;
}

//--------------------------------------------------------------------
//	insertObject:atIndex:

- (void)insertObject:anObject
	     atIndex:(unsigned)index
{
  BOOL insert = YES;

  LOGObjectFnStart();
  if(_delegateRespondsTo.shouldInsertObject == YES)
    insert = [_delegate displayGroup:self
		       shouldInsertObject:anObject
		       atIndex:index];

  if(insert)
    {
      NSDebugMLLog(@"gswdisplaygroup",@"insertObject:AtIndex: Will [_dataSource insertObject:anObject]");
      [_dataSource insertObject:anObject];
      NSDebugMLLog(@"gswdisplaygroup",@"insertObject:AtIndex: End [_dataSource insertObject:anObject]");
      
      [_allObjects insertObject:anObject 
                   atIndex:index];
      [self setCurrentBatchIndex:_batchIndex];
      
      if(_delegateRespondsTo.didInsertObject == YES)
        [_delegate displayGroup:self
                  didInsertObject:anObject];

      [self setSelectionIndexes:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:index]]];
    };
}

//--------------------------------------------------------------------
//	insertObjectAtIndex:

- (id)insertObjectAtIndex:(unsigned)index
{
  id object=nil;
  LOGObjectFnStart();

  NSDebugMLLog(@"gswdisplaygroup",@"Will [_dataSource createObject]");
  object = [_dataSource createObject];
  NSDebugMLLog(@"gswdisplaygroup",@"End [_dataSource createObject]. Object %p=%@",
               object,object);
  if(object == nil)
    {
      if(_delegateRespondsTo.createObjectFailed == YES)
	[_delegate displayGroup:self
		  createObjectFailedForDataSource:_dataSource];
    }
  else
    {
      [object takeValuesFromDictionary:[self insertedObjectDefaultValues]];
      NSDebugMLLog(@"gswdisplaygroup",@"Will insertObject:AtIndex:");
      [self insertObject:object
            atIndex:index];
      NSDebugMLLog(@"gswdisplaygroup",@"End insertObject:AtIndex:");
    };
  LOGObjectFnStop();
  return object;
}

//--------------------------------------------------------------------
//	lastQualifierFromInputValues

-(EOQualifier*)lastQualifierFromInputValues
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
  return nil;
};

//--------------------------------------------------------------------
//	localKeys

- (NSArray *)localKeys
{
  return _localKeys;
}

-(BOOL)usesOptimisticRefresh
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
  return NO;
};



-(void)setUsesOptimisticRefresh:(id)object_
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
};

-(void)awakeFromNib
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
};


//--------------------------------------------------------------------
//	masterObject

- (id)masterObject
{
  id obj=nil;
  LOGObjectFnStart();

  if([self hasDetailDataSource] == YES)
    obj=[(EODetailDataSource *)_dataSource masterObject];

  LOGObjectFnStop();
  return obj;
}

//--------------------------------------------------------------------
//	numberOfObjectsPerBatch

- (unsigned)numberOfObjectsPerBatch
{
  return _numberOfObjectsPerBatch;
}

//--------------------------------------------------------------------
//	qualifier

- (EOQualifier *)qualifier
{
  return _qualifier;
}

//--------------------------------------------------------------------
//	qualifierFromInputValues

-(EOQualifier*)qualifierFromInputValues
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
  return nil;
};

//--------------------------------------------------------------------
//	qualifierFromQueryValues

- (EOQualifier *)qualifierFromQueryValues
{
  //Near OK
  EOQualifier* resultQualifier=nil;
  NSMutableArray *array=nil;
  LOGObjectFnStart();
  NSDebugMLLog(@"gswdisplaygroup",@"_queryMatch=%@",
               _queryMatch);
  NSDebugMLLog(@"gswdisplaygroup",@"_defaultStringMatchOperator=%@ EOQualifier sel:%p",
               _defaultStringMatchOperator,
               (void*)[EOQualifier operatorSelectorForString:_defaultStringMatchOperator]);

  array = [NSMutableArray arrayWithCapacity:8];

  [self _addQualifiersToArray:array
        forValues:_queryMax
        operatorSelector:EOQualifierOperatorLessThan];//LessThan ??
  [self _addQualifiersToArray:array
        forValues:_queryMin
        operatorSelector:EOQualifierOperatorGreaterThan];//GreaterThan ??

  NSDebugMLLog(@"gswdisplaygroup",@"_defaultStringMatchOperator=%@ EOQualifier sel:%p",
               _defaultStringMatchOperator,
               (void*)[EOQualifier operatorSelectorForString:_defaultStringMatchOperator]);
  [self _addQualifiersToArray:array
        forValues:_queryMatch
        operatorSelector:[EOQualifier operatorSelectorForString:_defaultStringMatchOperator]];//VERIFY

  NSDebugMLLog(@"gswdisplaygroup",@"array=%@",array);
  if ([array count]==1)
    resultQualifier=[array objectAtIndex:0];
  else if ([array count]>1)
    resultQualifier=[[[EOAndQualifier alloc] initWithQualifierArray:array] autorelease];
  NSDebugMLLog(@"gswdisplaygroup",@"resultQualifier=%@",resultQualifier);
  LOGObjectFnStop();
  return resultQualifier;
}

//--------------------------------------------------------------------
//	qualifyDataSource

- (void)qualifyDataSource
{
  // near OK
  EOQualifier* qualifier=nil;
  LOGObjectFnStart();
  NS_DURING //for trace purpose
    {
      //TODO
      //[self endEditing];//WO45P3 ret 1 //TODO if NO ?
      [self setInQueryMode:NO];
      qualifier=[self qualifierFromQueryValues];//OK
      NSDebugMLLog(@"gswdisplaygroup",@"qualifier=%@",qualifier);
      NSDebugMLLog(@"gswdisplaygroup",@"_dataSource=%@",_dataSource);
      [_dataSource setAuxiliaryQualifier:qualifier];//OK

      NSDebugMLLog0(@"gswdisplaygroup",@"Will fetch");
      [self fetch];//OK use ret Value ?
      NSDebugMLLog0(@"gswdisplaygroup",@"End fetch");
    }
  NS_HANDLER
    {
      NSLog(@"%@ (%@)",localException,[localException reason]);
      LOGException(@"%@ (%@)",localException,[localException reason]);
      [localException raise];
    }
  NS_ENDHANDLER;
  LOGObjectFnStop();
};

//--------------------------------------------------------------------
//	qualifyDisplayGroup

- (void)qualifyDisplayGroup
{
  EOQualifier* qualifier=nil;
  LOGObjectFnStart();
  [self setInQueryMode:NO];
  qualifier=[self qualifierFromQueryValues];
  NSDebugMLLog(@"gswdisplaygroup",@"qualifier=%@",qualifier);
  [self setQualifier:qualifier];

  NSDebugMLLog0(@"gswdisplaygroup",@"updateDisplayedObjects");
  [self updateDisplayedObjects];
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	queryBindings

- (NSMutableDictionary *)queryBindings
{
  return _queryBindings;
}

//--------------------------------------------------------------------
//	queryMatch

- (NSMutableDictionary *)queryMatch
{
  return _queryMatch;
}

//--------------------------------------------------------------------
//	queryMax

- (NSMutableDictionary *)queryMax
{
  return _queryMax;
}

//--------------------------------------------------------------------
//	queryMin

- (NSMutableDictionary *)queryMin
{
  return _queryMin;
}

//--------------------------------------------------------------------
//	queryOperator

- (NSMutableDictionary *)queryOperator
{
  return _queryOperator;
}

//--------------------------------------------------------------------
//	redisplay

-(void)redisplay
{
  //VERIFY
  LOGObjectFnStart();
  [self _notifyRowChanged:-1]; // -1 ??
  LOGObjectFnStop();
};

//--------------------------------------------------------------------
//	relationalQualifierOperators

- (NSArray *)relationalQualifierOperators
{
  return [EOQualifier relationalQualifierOperators];
}

//--------------------------------------------------------------------
//	secondObjectForQualifier

-(NSMutableDictionary*)secondObjectForQualifier
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
  return nil;
};

//--------------------------------------------------------------------
//	selectedObject

- (id)selectedObject
{
  id obj=nil;
  LOGObjectFnStart();
  NSDebugMLLog(@"gswdisplaygroup",@"_selectedObjects count=%d",[_selectedObjects count]);
  if([_selectedObjects count])
    obj=[_selectedObjects objectAtIndex:0];
  NSDebugMLLog(@"gswdisplaygroup",@"selectedObject=%@",obj);

  LOGObjectFnStop();
  return obj;
}

//--------------------------------------------------------------------
//	selectedObjects

- (NSArray *)selectedObjects
{
  return _selectedObjects;
}

//--------------------------------------------------------------------
//	selectionIndexes

- (NSArray *)selectionIndexes
{
  return _selection;
}

//--------------------------------------------------------------------
//	selectFirst

- (id)selectFirst
{
  LOGObjectFnStart();

  if([_allObjects count]>0)
    {
      [self setSelectionIndexes:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:0]]];
    };
  return nil;//return nil for direct .gswd actions ==> same page
};  

//--------------------------------------------------------------------
//	selectNext

- (id)selectNext
{
  unsigned index=0;
  id obj=nil;
  LOGObjectFnStart();

  if([_allObjects count]>0)
    {
      if(![_selectedObjects count])
        [self setSelectionIndexes:[NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:0]]];
      else
        {
          obj = [_selectedObjects objectAtIndex:0];
          
          if([obj isEqual:[_displayedObjects lastObject]] == YES)
            {
              index = [_allObjects indexOfObject:[_displayedObjects
                                                   objectAtIndex:0]];
              
              [self setSelectionIndexes:
                      [NSArray arrayWithObject:
                                 [NSNumber numberWithUnsignedInt:index]]];
            }
          else
            {
              index = [_allObjects indexOfObject:obj]+1;
              
              if(index >= [_allObjects count])
                index = 0;
              
              [self setSelectionIndexes:
                      [NSArray arrayWithObject:
                                 [NSNumber numberWithUnsignedInt:index]]];
            };
        };
    };
  LOGObjectFnStop();
  return nil;//return nil for direct .gswd actions ==> same page
}

//--------------------------------------------------------------------
//	selectObject:

- (BOOL)selectObject:(id)object
{
  BOOL result=NO;
  LOGObjectFnStart();
  NSDebugMLLog(@"gswdisplaygroup",@"object=%@",object);
  NSDebugMLLog(@"gswdisplaygroup",@"_allObjects=%@",_allObjects);
  NSDebugMLLog(@"gswdisplaygroup",@"[_allObjects containsObject:object]=%d",
               (int)[_allObjects containsObject:object]);
  if(![_allObjects containsObject:object])
    result=NO;
  else
    result=[self setSelectionIndexes:
                   [NSArray arrayWithObject:
                              [NSNumber numberWithUnsignedInt:
                                          [_allObjects
                                            indexOfObject:object]]]];
  NSDebugMLLog(@"gswdisplaygroup",@"result=%d",(int)result);
  LOGObjectFnStop();
  return result;
}

//--------------------------------------------------------------------
//	selectObjectsIdenticalTo:
- (BOOL)selectObjectsIdenticalTo:(NSArray *)objects
{
  BOOL result=NO;
  NSMutableArray *array=nil;
  NSEnumerator *objsEnum=nil;
  NSEnumerator *dispEnum=nil;
  id object=nil;
  id dispObj=nil;
  LOGObjectFnStart();

  // Array of new selected indexes
  array = [NSMutableArray arrayWithCapacity:8];

  // ENumeratoe Objects to select
  objsEnum = [objects objectEnumerator];

  // For each object to select
  while((object = [objsEnum nextObject]))
    {
      //Enumerated displayed objects
      dispEnum = [_displayedObjects objectEnumerator];

      // For each already displayed object
      while((dispObj = [dispEnum nextObject]))
	{
          //if object to select is displayed
	  if(dispObj == object)
	    {
              // Add it to array of selected indexes
	      [array addObject:[NSNumber numberWithUnsignedInt:
					   [_allObjects indexOfObject:object]]];
	      break;
	    };
	};

      //???
      if(dispObj == nil)
	{
	  [array removeAllObjects];
	  break;
	};
    };
  result=[self setSelectionIndexes:array];
  LOGObjectFnStop();
  return result;
}

//--------------------------------------------------------------------
//	selectObjectsIdenticalTo:selectFirstOnNoMatch:

- (BOOL)selectObjectsIdenticalTo:(NSArray *)objects
	    selectFirstOnNoMatch:(BOOL)flag
{


/*
//--------------------------------------------------------------------
//	selectObjectsIdenticalTo:selectFirstOnNoMatch: //WO45
-(BOOL)selectObjectsIdenticalTo:(NSArray*)objects //0x1962ca8

           selectFirstOnNoMatch:(int)index //0
{
self setSelectionIndexes:indexes of objects in objects? //ret 1
  return 1; ??
}
*/

  BOOL result=NO;
  unsigned index=0;
  LOGObjectFnStart();
  if([self selectObjectsIdenticalTo:objects] == NO && flag == YES)
    {
      if(![_selectedObjects count] &&
	 [_displayedObjects count])
	{
	  index = [_allObjects indexOfObject:[_displayedObjects
					      objectAtIndex:0]];
	  [self setSelectionIndexes:
		  [NSArray arrayWithObject:[NSNumber
					     numberWithUnsignedInt:index]]];
	  result=YES;
	}
      else
        result=NO;
    }
  else
    result=YES;
  LOGObjectFnStop();
  return result;
}

//--------------------------------------------------------------------
//	selectPrevious

- (id)selectPrevious
{
  unsigned index=0;
  id obj=nil;
  LOGObjectFnStart();

  if([_allObjects count]>0)
    {
      if(![_selectedObjects count])
        [self setSelectionIndexes:
                [NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:0]]];
      else
        {
          obj = [_selectedObjects objectAtIndex:0];
          
          if([obj isEqual:[_displayedObjects objectAtIndex:0]] == YES)
            {
              index = [_allObjects indexOfObject:[_displayedObjects lastObject]];
              
              [self setSelectionIndexes:
                      [NSArray arrayWithObject:
                                 [NSNumber numberWithUnsignedInt:index]]];
            }
          else
            {
              index = [_allObjects indexOfObject:obj]-1;
              
              if(!index || index >= [_allObjects count])
                index = [_allObjects count] - 1;
              
              [self setSelectionIndexes:
                      [NSArray arrayWithObject:
                                 [NSNumber numberWithUnsignedInt:index]]];
            };
        };
    };
  LOGObjectFnStop();
  return nil;
}

//--------------------------------------------------------------------
//	selectsFirstObjectAfterFetch

- (BOOL)selectsFirstObjectAfterFetch
{
  LOGObjectFnStart();
  return _flags.selectFirstObject;
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	setBuildsQualifierFromInput:

- (void)setBuildsQualifierFromInput:(BOOL)flag
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
};

//--------------------------------------------------------------------
//	setCurrentBatchIndex:

- (void)setCurrentBatchIndex:(unsigned)index
{
  unsigned batchCount, num;
  int i;
  LOGObjectFnStart();

  if(index)
    {
      [_displayedObjects removeAllObjects];
      
      batchCount = [self batchCount];
		NSLog(@"setCurrentBatchIndex : [self batchCount] = %d", [self batchCount]);
      if(index > batchCount)
        index = 1;
      
      num = [_allObjects count];
		NSLog(@"setCurrentBatchIndex : [_allObjects count] = %d", [_allObjects count]);

      if(_numberOfObjectsPerBatch && _numberOfObjectsPerBatch < num)
        num = _numberOfObjectsPerBatch;
      
      if(num)
        {
		NSLog(@"setCurrentBatchIndex : index = %d", index);
		NSLog(@"setCurrentBatchIndex : num = %d", num);

          for( i = (index-1) * num;
               ((i < index * num) && (i < [_allObjects count]));
               i++)
            [_displayedObjects addObject:[_allObjects objectAtIndex:i]];
          
          //if(_flags.selectFirstObject == YES && [_selection count])
          if ((_flags.selectFirstObject == YES) && [_displayedObjects count])
            [self setSelectionIndexes:
                    [NSArray arrayWithObject:
                               [NSNumber numberWithUnsignedInt:
                                           [_allObjects
                                             indexOfObject:
                                               [_displayedObjects objectAtIndex:0]]]]];
        };
    };
  LOGObjectFnStop();
}

-(void)_checkSelectedBatchConsistency
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
};


-(BOOL)_allowsNullForKey:(id)key
{
  LOGObjectFnStart();
  LOGObjectFnNotImplemented();	//TODOFN
  LOGObjectFnStop();
  return NO;
};


//--------------------------------------------------------------------
//	setDefaultStringMatchFormat:

- (void)setDefaultStringMatchFormat:(NSString *)format
{
  LOGObjectFnStart();
  ASSIGN(_defaultStringMatchFormat, format);
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	setDefaultStringMatchOperator:

- (void)setDefaultStringMatchOperator:(NSString *)operator
{
  LOGObjectFnStart();
  ASSIGN(_defaultStringMatchOperator, operator);
  LOGObjectFnStop();
}


//--------------------------------------------------------------------
//	setDetailKey:

- (void)setDetailKey:(NSString *)detailKey
{
  EODetailDataSource *source=nil;
  LOGObjectFnStart();

  if([self hasDetailDataSource] == YES)
    {
      source = (EODetailDataSource *)_dataSource;
      [source qualifyWithRelationshipKey:detailKey
	      ofObject:[source masterObject]];
    }
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	setFetchesOnLoad:

- (void)setFetchesOnLoad:(BOOL)flag
{
  LOGObjectFnStart();
  _flags.autoFetch = flag;
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	setInQueryMode:

- (void)setInQueryMode:(BOOL)flag
{
  LOGObjectFnStart();
//[self inQueryMode]//WO45P3
  _flags.queryMode = flag;
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	setInsertedObjectDefaultValues:

- (void)setInsertedObjectDefaultValues:(NSDictionary *)defaultValues
{
  LOGObjectFnStart();
  ASSIGN(_insertedObjectDefaultValues, defaultValues);
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	setLocalKeys:

- (void)setLocalKeys:(NSArray *)keys
{
  LOGObjectFnStart();
  ASSIGN(_localKeys, keys);
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
/** sets query operators **/
-(void)setQueryOperator:(NSDictionary*)qo
{
  NSAssert1((!qo || [qo isKindOfClass:[NSDictionary class]]),
            @"queryOperator is not a dictionary but a %@",
            [qo class]);
  [_queryOperator removeAllObjects];
  if (qo)
    [_queryOperator addEntriesFromDictionary:qo];
};

//--------------------------------------------------------------------
//	setMasterObject:

- (void)setMasterObject:(id)masterObject
{
  //OK
  EODetailDataSource *source=nil;
  LOGObjectFnStart();
  NSDebugMLLog(@"gswdisplaygroup",@"masterObject=%@",masterObject);
  if([self hasDetailDataSource] == YES)
    {
      source = (EODetailDataSource *)_dataSource;
      NSDebugMLLog(@"gswdisplaygroup",@"source=%@",source);
      NSDebugMLLog(@"gswdisplaygroup",@"[source detailKey]=%@",[source detailKey]);
      [_dataSource qualifyWithRelationshipKey:[source detailKey]
		  ofObject:masterObject];
      if ([self fetchesOnLoad])
        {
          NSDebugMLLog(@"gswdisplaygroup",@"will fetch");
          [self fetch];
        };
    };
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	setNumberOfObjectsPerBatch:

- (void)setNumberOfObjectsPerBatch:(unsigned)count
{
  LOGObjectFnStart();
//FIXME  call clearSelection

  _numberOfObjectsPerBatch = count;
  _batchIndex=max(1,_batchIndex);
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	setObjectArray:

- (void)setObjectArray:(NSArray *)objects
{
  LOGObjectFnStart();
//self selectedObjects
// self updateDisplayedObjects
  NSDebugMLog(@"objects=%@",objects);

  [_allObjects removeAllObjects];
  [_allObjects addObjectsFromArray:objects];

  [self updateDisplayedObjects];

  if ([self selectsFirstObjectAfterFetch])
    {
      [self selectObjectsIdenticalTo:_selection //TODO _selection ?? 
            selectFirstOnNoMatch:1];
      [self redisplay];
    }

  // TODO selection
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	setQualifier:

- (void)setQualifier:(EOQualifier *)qualifier
{
  LOGObjectFnStart();
  ASSIGN(_qualifier, qualifier);
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	setSelectedObject:

- (void)setSelectedObject:(id)object
{
  LOGObjectFnStart();
  [self selectObject:object];
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	setSelectedObjects:

- (void)setSelectedObjects:(NSArray *)objects
{
  NSMutableArray *indexArray;
  NSEnumerator   *enumerator;
  id              object;

  LOGObjectFnStart();

  indexArray = [NSMutableArray arrayWithCapacity:16];

  enumerator = [objects objectEnumerator];
  while((object = [enumerator nextObject]))
    {
      if([_allObjects containsObject:object] == YES)
	[indexArray addObject:[NSNumber numberWithUnsignedInt:
					  [_allObjects indexOfObject:object]]];
    }

  [self setSelectionIndexes:indexArray];

  LOGObjectFnStop();
}
//--------------------------------------------------------------------
//	setSelectionIndexes:

- (BOOL)setSelectionIndexes:(NSArray *)selection_
{
//(0) object 0x2859148 
/*
if objects to selet and no prev selection
{
[self endEditing]//ret 1
ASSIGN(_selection,selection_); //Array of indexes
[self _notifySelectionChanged]
STOP ?
}


*/



  NSEnumerator *objsEnum=nil;
  NSNumber *number=nil;
  BOOL	stop = NO;
  BOOL retValue=NO;
  LOGObjectFnStart();
//call selectedObjects //
  if(_delegateRespondsTo.shouldChangeSelection == YES 
     && [_delegate displayGroup:self
                  shouldChangeSelectionToIndexes:selection_] == NO)
    retValue=NO;
  else
    {
      objsEnum = [selection_ objectEnumerator];
      while((number = [objsEnum nextObject]))
        {
          NS_DURING
            {
              // check for objects
              [_allObjects objectAtIndex:[number unsignedIntValue]];
            }
          NS_HANDLER
            {
              //return NO;
              stop = YES;
              retValue=NO;
            }
          NS_ENDHANDLER;
        }

      if (!stop)
        {
          [_selectedObjects removeAllObjects];
          
          objsEnum = [selection_ objectEnumerator];
          while((number = [objsEnum nextObject]))
            {
              [_selectedObjects   addObject:[_allObjects objectAtIndex:[number unsignedIntValue]]];
            }

          ASSIGN(_selection, selection_);
          
          if(_delegateRespondsTo.didChangeSelection == YES)
            [_delegate displayGroupDidChangeSelection:self];
      
          if(_delegateRespondsTo.didChangeSelectedObjects == YES)
            [_delegate displayGroupDidChangeSelectedObjects:self];
        };
    };
  LOGObjectFnStop();
  return retValue;
}

//--------------------------------------------------------------------
//	setSelectsFirstObjectAfterFetch:

- (void)setSelectsFirstObjectAfterFetch:(BOOL)flag
{
  LOGObjectFnStart();
  _flags.selectFirstObject = flag;
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	setSortOrdering:

- (void)setSortOrderings:(NSArray *)orderings
{
  LOGObjectFnStart();
  ASSIGN(_sortOrdering, orderings);
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	setValidatesChangesImmediately:

- (void)setValidatesChangesImmediately:(BOOL)flag
{
  LOGObjectFnStart();
  _flags.validateImmediately = flag;
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	sortOrdering

- (NSArray *)sortOrderings
{
  LOGObjectFnStart();
  LOGObjectFnStop();
  return _sortOrdering;
}

//--------------------------------------------------------------------
//	updateDisplayedObjects

- (void)updateDisplayedObjects
{
  NSEnumerator *objsEnum=nil;
  id object=nil;
  LOGObjectFnStart();

//TODO
//self selectedObjects //() 
//self allObjects 
//self selectObjectsIdenticalTo:_selection selectFirstOnNoMatch:0
//self redisplay
//STOP
  [_displayedObjects removeAllObjects];

  if(_delegateRespondsTo.displayArrayForObjects == YES)
    {
      [_displayedObjects addObjectsFromArray:[_delegate displayGroup:self
                                                        displayArrayForObjects:_allObjects]];
    }
  else
    {
      if(_qualifier)
        {
          objsEnum = [_allObjects objectEnumerator];
          while((object = [objsEnum nextObject]))
            {
              if([_qualifier evaluateWithObject:object] == YES)
                [_displayedObjects addObject:object];
            }
        }
      else
        {
          _batchIndex = [self batchCount];
          NSDebugMLog(@"_batchIndex=%d",_batchIndex);
          [self displayNextBatch];
        }
      
      if(_sortOrdering)
        [_displayedObjects sortUsingKeyOrderArray:_sortOrdering];
    };
  LOGObjectFnStop();
}

//--------------------------------------------------------------------
//	validatesChangesImmediately

- (BOOL)validatesChangesImmediately
{
  LOGObjectFnStart();
  LOGObjectFnStop();
  return _flags.validateImmediately;
}

- (id)initWithCoder:(NSCoder *)coder
{
  LOGObjectFnStart();
  [self notImplemented:_cmd];
  LOGObjectFnStop();
  return nil;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  LOGObjectFnStart();
  [self notImplemented:_cmd];
  LOGObjectFnStop();
}

#endif

@end
