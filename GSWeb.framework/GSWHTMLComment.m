/** GSWHTMLComment.m - <title>GSWeb: Class GSWRequest</title>

   Copyright (C) 1999-2003 Free Software Foundation, Inc.
   
   Written by:	Manuel Guesdon <mguesdon@orange-concept.com>
   Date: 	Sept 1999
   
   $Revision$
   $Date$

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

#include "config.h"

RCS_ID("$Id$")

#include "GSWeb.h"

//====================================================================
@implementation GSWHTMLComment

//--------------------------------------------------------------------
-(id)init
{
  if ((self=[super init]))
    {
      _encoding = [GSWMessage defaultEncoding];
    };
  return self;
};

//--------------------------------------------------------------------
-(id)initWithString:(NSString*)aString
{
  if ((self=[self init]))
    {
      ASSIGN(_string,aString);
    };
  return self;
};

//--------------------------------------------------------------------
-(void)dealloc
{
  DESTROY(_string);
  DESTROY(_data);
  [super dealloc];
}

//--------------------------------------------------------------------
-(NSString*)description
{
  return [NSString stringWithFormat:@"<%s %p - String:[%@]>",
                   object_get_class_name(self),
                   (void*)self,
                   _string];
};

@end

//====================================================================
@implementation GSWHTMLComment (GSWHTMLCommentA)

//--------------------------------------------------------------------
-(void)appendToResponse:(GSWResponse*)aResponse
              inContext:(GSWContext*)aContext
{
  LOGObjectFnStart();
  NSDebugMLLog(@"gswdync",@"ET=%@ id=%@",[self class],[aContext elementID]);
  [aResponse _appendContentAsciiString:@"<!--"];
  [aResponse _appendContentAsciiString:_string];
  [aResponse _appendContentAsciiString:@"-->"];
  NSDebugMLLog(@"gswdync",@"END ET=%@ id=%@",[self class],[aContext elementID]);
  LOGObjectFnStop();
};

@end

//====================================================================
@implementation GSWHTMLComment (GSWHTMLCommentB)

//--------------------------------------------------------------------
+(id)elementWithString:(NSString*)aString
{
  return [[[GSWHTMLComment alloc]initWithString:aString] autorelease];
};
@end
