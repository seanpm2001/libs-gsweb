/** GSWVBScript.m - <title>GSWeb: Class GSWVBScript</title>

   Copyright (C) 1999-2003 Free Software Foundation, Inc.
   
   Written by:	Manuel Guesdon <mguesdon@orange-concept.com>
   Date: 		Jan 1999
      
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
@implementation GSWVBScript

-(id)initWithName:(NSString*)aName
     associations:(NSDictionary*)associations
         template:(GSWElement*)templateElement
{
  GSWAssociation* languageAssociation=nil;
  NSMutableDictionary* tmpAssociations=[NSMutableDictionary dictionaryWithDictionary:associations];
  LOGObjectFnStartC("GSWVBScript");
  NSDebugMLLog(@"gswdync",@"aName=%@ associations:%@ templateElement=%@",aName,associations,templateElement);
  if (![tmpAssociations objectForKey:language__Key])
    {
      // Create and set the language (Javascript)
      languageAssociation=[GSWConstantValueAssociation associationWithValue:@"VBScript"]; //???
      [tmpAssociations setObject:languageAssociation
                       forKey:language__Key];
    };
  if ((self=[super initWithName:aName
                   associations:tmpAssociations
                   template:templateElement]))
    {
    };
  return self;
};
//--------------------------------------------------------------------

@end
