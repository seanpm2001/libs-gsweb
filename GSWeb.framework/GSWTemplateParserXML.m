/* GSWTemplateParserXML.m - GSWeb: Class GSWTemplateParserXML
   Copyright (C) 1999 Free Software Foundation, Inc.
   
   Written by:	Manuel Guesdon <mguesdon@sbuilders.com>
   Date: 		Mar 1999
   
   This file is part of the GNUstep Web Library.
   
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
*/

static char rcsId[] = "$Id$";

#include <GSWeb/GSWeb.h>
#include <libxml/SAX.h>
#include <libxml/xml-error.h>

extern xmlParserInputPtr xmlNewStringInputStream(xmlParserCtxtPtr ctxt,
                                                 const xmlChar *buffer);

static NSLock* GSXMLParserLock=nil;
static NSMutableDictionary* DTDCache=nil;

//====================================================================
@implementation GSWTemplateParserSAXHandler

//--------------------------------------------------------------------
+ (void) initialize
{
  // Initialize DTD Cache, and Lock
  if (self==[GSWTemplateParserSAXHandler class])
    {
      if (!DTDCache)
        DTDCache=[NSMutableDictionary new];
      if (!GSXMLParserLock)
        GSXMLParserLock=[NSRecursiveLock new];
    };
};

//--------------------------------------------------------------------
+(void)dealloc
{
  // Dealloc DTD Cache and Lock
  if (self==[GSWTemplateParserSAXHandler class])
    {
      DESTROY(DTDCache);
      DESTROY(GSXMLParserLock);
    };
};

//--------------------------------------------------------------------
/*"Lock"*/
+(void)lock
{
  NS_DURING
    {
      [GSXMLParserLock lock];
    }
  NS_HANDLER
    {
      NSLog(@"EXCEPTION:(GSXMLParserLock lock) %@ (%@) [%s %d]",localException,[localException reason],__FILE__,__LINE__);
      [localException raise];
    };
  NS_ENDHANDLER;
};

//--------------------------------------------------------------------
/*"Unlock"*/
+(void)unlock
{
  NS_DURING
    {
      [GSXMLParserLock unlock];
    }
  NS_HANDLER
    {
      NSLog(@"EXCEPTION:(GSXMLParserLock unlock) %@ (%@) [%s %d]",localException,[localException reason],__FILE__,__LINE__);
      [localException raise];
    };
  NS_ENDHANDLER;
};

//--------------------------------------------------------------------
/*"Find cached DTD Content for Key url"*/
+(NSString*)cachedDTDContentForKey:(NSString*)url
{
  NSString* content=nil;
  [self lock];
  content=[DTDCache objectForKey:url];
  [self unlock];
  return content;
};

//--------------------------------------------------------------------
/*"Cache DTD Content externalContent for Key url"*/
+(void)setCachedDTDContent:(NSString*)externalContent
                    forKey:(NSString*)url
{
  [self lock];
  [DTDCache setObject:externalContent
            forKey:url];
  [self unlock];
};

//--------------------------------------------------------------------
+(id)handlerWithTemplateParser:(GSWTemplateParser*)templateParser_
{
  return AUTORELEASE([[self alloc] initWithTemplateParser:templateParser_]);
};  

extern void            externalSubset                  (void *ctx,
                                                        const xmlChar *name,
                                                        const xmlChar *ExternalID,
                                                        const xmlChar *SystemID);

//--------------------------------------------------------------------
-(id)initWithTemplateParser:(GSWTemplateParser*)templateParser_
{
  if ((self=[self init]))
    {
      _templateParser=templateParser_;
      NSLog(@"my sax lib=%p",lib);
      if (lib)
        {
          xmlSAXHandlerPtr def=NULL;
          if ([_templateParser isKindOfClass:[GSWTemplateParserXMLHTML class]])
            def=&htmlDefaultSAXHandler;
          else
            def=&xmlDefaultSAXHandler;
          ((xmlSAXHandlerPtr)lib)->internalSubset         = def->internalSubset;
          ((xmlSAXHandlerPtr)lib)->isStandalone           = def->isStandalone;
          ((xmlSAXHandlerPtr)lib)->hasInternalSubset      = def->hasInternalSubset;
          ((xmlSAXHandlerPtr)lib)->hasExternalSubset      = def->hasExternalSubset;
          ((xmlSAXHandlerPtr)lib)->resolveEntity          = def->resolveEntity;
          ((xmlSAXHandlerPtr)lib)->getEntity              = def->getEntity;
          ((xmlSAXHandlerPtr)lib)->entityDecl             = def->entityDecl;
          ((xmlSAXHandlerPtr)lib)->notationDecl           = def->notationDecl;
          ((xmlSAXHandlerPtr)lib)->attributeDecl          = def->attributeDecl;
          ((xmlSAXHandlerPtr)lib)->elementDecl            = def->elementDecl;
          ((xmlSAXHandlerPtr)lib)->unparsedEntityDecl     = def->unparsedEntityDecl;
          ((xmlSAXHandlerPtr)lib)->startDocument          = def->startDocument;
          ((xmlSAXHandlerPtr)lib)->endDocument            = def->endDocument;
          ((xmlSAXHandlerPtr)lib)->startElement           = def->startElement;
          ((xmlSAXHandlerPtr)lib)->endElement             = def->endElement;
          ((xmlSAXHandlerPtr)lib)->reference              = def->reference;
          ((xmlSAXHandlerPtr)lib)->characters             = def->characters;
          ((xmlSAXHandlerPtr)lib)->ignorableWhitespace    = def->ignorableWhitespace;
          ((xmlSAXHandlerPtr)lib)->processingInstruction  = def->processingInstruction;
          ((xmlSAXHandlerPtr)lib)->comment                = def->comment;
          //    ((xmlSAXHandlerPtr)lib)->warning                = xmlParserWarning;
          //    ((xmlSAXHandlerPtr)lib)->error                  = xmlParserError;
          //    ((xmlSAXHandlerPtr)lib)->fatalError             = xmlParserError;
          ((xmlSAXHandlerPtr)lib)->getParameterEntity     = def->getParameterEntity;
          ((xmlSAXHandlerPtr)lib)->cdataBlock             = def->cdataBlock;
          ((xmlSAXHandlerPtr)lib)->externalSubset         = def->externalSubset;
        };
    };
  return self;
};

-(id)init
{
  if ((self=[super init]))
    {
    };
  return self;
};

xmlParserInputPtr GSWTemplateParserSAXHandler_ExternalLoader(const char *systemId,
                                                             const char *publicId,
                                                             xmlParserCtxtPtr context)
{
/*
  NSCAssert(context,@"No Parser Context");
  NSCAssert(context->_private,@"No GSSAXHandler reference in Parser Context");
  return [(GSSAXHandler*)(context->_private)resolveEntity:[NSString stringWithCString:publicId]
                         systemID:[NSString stringWithCString:systemId]];
*/
  return NULL;
}


//--------------------------------------------------------------------
//exemple:
// publicIdEntity
//		-//IETF//DTD HTML//EN
// 		-//W3C//ENTITIES Special for XHTML//EN
//		-//W3C//ENTITIES Symbols for XHTML//EN
//		-//W3C//ENTITIES Latin 1 for XHTML//EN
//		-//W3C//DTD XHTML 1.0 Transitional//EN
//		-//W3C//DTD XHTML 1.0 Strict//EN
//		-//W3C//DTD XHTML 1.0 Frameset//EN
//		-//W3C//DTD HTML 4.01//EN
//		-//W3C//DTD HTML 4.01 Transitional//EN
//		-//W3C//DTD HTML 4.01 Frameset//EN
//		-//IETF//DTD HTML//EN
//		-//W3C//DTD HTML 3.2//EN
// systemIdEntity
//		http://www.w3c.org/html.dtd
//		html.dtd

-(xmlParserInputPtr)resolveEntity:(NSString*)publicIdEntity
                         systemID:(NSString*)systemIdEntity
{
  NSString* externalContent=nil;
  xmlParserInputPtr	result = 0;
  LOGObjectFnStart();
  NSLog(@"resolveEntity:%@ systemID:%@ inParserContext:%p\n",
        publicIdEntity,
        systemIdEntity,
        lib);
  NSAssert(publicIdEntity || systemIdEntity,
           @"resolveEntity:systemIdEntity: publicIdEntity and systemIdEntity are both nil");
  if (systemIdEntity)
    {
      externalContent=[[self class] cachedDTDContentForKey:systemIdEntity];
      if (!externalContent)
        {
          NSString* fileName=nil;
          NSString* resourceName=systemIdEntity;
          if ([[resourceName pathExtension] isEqual:@"dtd"])
            resourceName=[resourceName stringByDeletingPathExtension];
          fileName = [[NSBundle bundleForClass: [self class]]
		       pathForResource:resourceName
		       ofType:@"dtd"
		       inDirectory:@"DTDs"];
          NSLog(@"systemIdEntity: fileName=%@ for Resource:%@",fileName,resourceName);
          if (fileName)
            {
              externalContent=[NSString stringWithContentsOfFile:fileName];
            };
          externalContent=[NSString stringWithContentsOfFile:fileName];
          if (externalContent)
            {
              NSString* gswebTag=@"\n<!ELEMENT gsweb %Flow;>
<!ATTLIST gsweb
  %attrs;
  >\n";
              //  name       NMTOKEN;       #IMPLIED
              NSLog(@"gswebTag=\n%@",gswebTag);
              externalContent=[externalContent stringByAppendingString:gswebTag];

              [[self class] setCachedDTDContent:externalContent
                            forKey:systemIdEntity];
            };
        };
    };
  if (!externalContent && publicIdEntity)
    {
      externalContent=[[self class] cachedDTDContentForKey:publicIdEntity];
      if (!externalContent)
        {
          //Well Known DTDs / Entities
          if ([publicIdEntity hasPrefix:@"-//"])
            {
              // 0: -
              // 1: W3C or IETF
              // 2: DTD ... or ENTITIES ...
              // 3: EN or ... (language)
              NSArray* parts=[publicIdEntity componentsSeparatedByString:@"//"];
              if ([parts count]>=2)
                {
                  NSString* whatPart=[parts objectAtIndex:2];
                  if ([whatPart hasPrefix:@"DTD"])
                    {
                      NSString* resourceName=nil;
                      NSString* fileName=nil;
                      if ([whatPart rangeOfString:@"Transitional"].length>0)
                        resourceName=@"xhtml1-transitional.dtd";
                      else if ([whatPart rangeOfString:@"Strict"].length>0)
                        resourceName=@"xhtml1-strict.dtd";
                      else if ([whatPart rangeOfString:@"Frameset"].length>0)
                        resourceName=@"xhtml1-frameset.dtd";
                      else
                        {
                          NSLog(@"Unknown DTD: %@. Choose default: xhtml1-transitional.dtd",publicIdEntity);
                          resourceName=@"xhtml1-transitional.dtd"; // guess
                        };
                      if (resourceName)
                        {
                          if ([[resourceName pathExtension] isEqual:@"dtd"])
                            resourceName=[resourceName stringByDeletingPathExtension];
                          fileName = [[NSBundle bundleForClass: [self class]]
				       pathForResource:resourceName
				       ofType:@"dtd"
				       inDirectory:@"DTDs"];
                          NSLog(@"systemIdEntity: fileName=%@ for Resource:%@",fileName,publicIdEntity);
                          if (fileName)
                            {
                              externalContent=[NSString stringWithContentsOfFile:fileName];
                            };
                        };
                    }
                  else if ([whatPart hasPrefix:@"ENTITIES"])
                    {
                      NSString* resourceName=nil;
                      NSString* fileName=nil;
                      if ([whatPart rangeOfString:@"Symbols"].length>0)
                        resourceName=@"xhtml-symbol.ent";
                      else if ([whatPart rangeOfString:@"Special"].length>0)
                        resourceName=@"xhtml-special.ent";
                      else if ([whatPart rangeOfString:@"Latin 1"].length>0)
                        resourceName=@"xhtml-lat1.ent";
                      else
                        {
                          NSLog(@"Unknown ENTITIES: %@",publicIdEntity);
                        };
                      if (resourceName)
                        {
                          if ([[resourceName pathExtension] isEqual:@"ent"])
                            resourceName=[resourceName stringByDeletingPathExtension];
                          fileName = [[NSBundle bundleForClass: [self class]]
				       pathForResource:resourceName
				       ofType:@"ent"
				       inDirectory:@"DTDs"];
                          NSLog(@"systemIdEntity: fileName=%@ for Resource:%@",fileName,publicIdEntity);
                          if (fileName)
                            {
                              externalContent=[NSString stringWithContentsOfFile:fileName];
                            };
                        };
                    }
                  else
                    {
                      NSLog(@"Unknown publicIdEntity %@",publicIdEntity);
                    };
                }
              else
                {
                  NSLog(@"Don't know how to parse publicIdEntity %@",publicIdEntity);
                };
            }
          else
            {
              NSLog(@"Don't know what to do with publicIdEntity %@",publicIdEntity);
            };
          if (externalContent)
            [[self class] setCachedDTDContent:externalContent
                          forKey:publicIdEntity];
        };
    };
  if (externalContent)
    {
      result=xmlNewStringInputStream(lib,[externalContent cString]);
    };
  NSAssert2(result,@"Can't load external (publicIdEntity:%@ systemIdEntity:%@)",publicIdEntity,systemIdEntity);
  NSLog(@"LOADED: resolveEntity:%@ systemID:%@ inParserContext:%p\n",
        publicIdEntity,
        systemIdEntity,
        lib);
  LOGObjectFnStop();
  return result;
};

//--------------------------------------------------------------------
-(void)warning:(NSString*)message
{
  [[GSWApplication application] logWithFormat:@"%@ Warning: %@",
                                [_templateParser logPrefix],
                                message];
};

//--------------------------------------------------------------------
-(void)error: (NSString*)message
{
  [[GSWApplication application] logErrorWithFormat:@"%@ Error: %@",
                                [_templateParser logPrefix],
                                message];
};

//--------------------------------------------------------------------
-(void)fatalError: (NSString*)message
{
  [[GSWApplication application] logErrorWithFormat:@"%@ Fatal Error: %@",
                                [_templateParser logPrefix],
                                message];
};

@end

//====================================================================
@implementation GSWTemplateParserXML

//--------------------------------------------------------------------
-(void)dealloc
{
  DESTROY(_xmlDocument);
  [super dealloc];
};

//--------------------------------------------------------------------
static NSString* TabsForLevel(int level)
{
  int i=0;
  NSMutableString* tabs=[NSMutableString string];
  for (i=0;i<level;i++)
    {
      [tabs appendString:@"\t"];
    };
  return tabs;
};

//--------------------------------------------------------------------
-(NSString*)dumpNode:(GSXMLNode*)node
             atLevel:(int)level
{
  NSString* dumpString=[NSString string];
  while (node)
    {
      dumpString=[dumpString stringByAppendingFormat:@"%@%@ [Type:%@] [%@]:\n%@\n",
                             TabsForLevel(level),
                             [node name],
                             [node typeDescription],
                             [node propertiesAsDictionary],
                             [node content]];
      if ([node children])
        dumpString=[dumpString stringByAppendingString:[self dumpNode:[node children]
                                                             atLevel:level+1]];
      node=[node next];
    };
  return dumpString;
};

//--------------------------------------------------------------------
-(NSArray*)templateElements
{
  NSArray* elements=nil;
  LOGObjectFnStart();
  if (!_xmlDocument)
    {
      BOOL parseOk=NO;
      GSXMLParser* parser=nil;
      GSWTemplateParserSAXHandler* sax=nil;
      NSStringEncoding stringEncoding=_stringEncoding;

      if (stringEncoding==GSUndefinedEncoding)
        stringEncoding=NSISOLatin1StringEncoding;
        
      sax=[GSWTemplateParserSAXHandler handlerWithTemplateParser:self];
      //NSLog(@"SAX=%p",sax);
      NSLog(@"self class=%@",[self class]);
      if ([self isKindOfClass:[GSWTemplateParserXMLHTML class]])
        parser=[GSHTMLParser parserWithSAXHandler:sax
                             withData:[_string dataUsingEncoding:stringEncoding]];
      else
        {
          NSString* xmlHeader=nil;
          NSRange docTypeRange=NSMakeRange(NSNotFound,0);
          NSString* stringToParse=nil;
          //NSLog(@"stringEncoding=%d",(int)stringEncoding);
          NSString* encodingString=nil;
          //NSLog(@"_string=%@",_string);
          encodingString=[GSXMLParser xmlEncodingStringForStringEncoding:stringEncoding];
          //NSLog(@"encodingString=%@",encodingString);
          if (encodingString)
            encodingString=[NSString stringWithFormat:@" encoding=\"%@\"",encodingString];
          else
            encodingString=@"";
          //NSLog(@"encodingString=%@",encodingString);
          xmlHeader=[NSString stringWithFormat:@"<?xml version=\"%@\"%@?>\n",
                              @"1.0",
                              encodingString];
          //NSLog(@"xmlHeader=%@",xmlHeader);
          //NSLog(@"_string=%@",_string);
          docTypeRange=[_string rangeOfString:@"<!DOCTYPE"];
          if (docTypeRange.length==0)
            stringToParse=[@"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"xhtml1-transitional.dtd\">\n" stringByAppendingString:_string];
          else
            stringToParse=_string;
          //NSLog(@"stringToParse=%@",stringToParse);      
          stringToParse=[xmlHeader stringByAppendingString:stringToParse];
          NSLog(@"stringToParse=%@",stringToParse);
          parser=[GSXMLParser parserWithSAXHandler:sax
                               withData:[stringToParse dataUsingEncoding:stringEncoding]];            
        };
      [parser doValidityChecking:YES];
      [parser getWarnings:YES];
      [parser setExternalEntityLoader:GSWTemplateParserSAXHandler_ExternalLoader];
      NS_DURING
        {
          parseOk=[parser parse];
        }
      NS_HANDLER
        {
          LOGError(@"%@ Exception in parse! Exception: %@",
                   [self logPrefix],
                   localException);
          localException=ExceptionByAddingUserInfoObjectFrameInfo(localException,
                                                                  @"%@ - In [parser parse] Exception!",
                                                                  [self logPrefix]);
          [localException retain];
          [localException autorelease];
          [localException raise];
        }
      NS_ENDHANDLER;
      if (!parseOk)
        {
          NSDebugMLog(@"######Parse FAILED errNo=%d [parser doc]=%p",
                      [parser errNo],
                      [parser doc]);
          // May be validity errors only (like no HTML root)
          if ([parser doc])
            parseOk=YES;
        };
      if (parseOk)
        {
          GSXMLNode* node=nil;
          NSDebugMLog(@"Root");
          ASSIGN(_xmlDocument,[parser doc]);
          node=[_xmlDocument root];
          NSAssert1(node,@"%@ Empty Document (root)",
                    [self logPrefix]);
#ifndef NDEBUG
          {
            NSString* dumpString=[self dumpNode:node
                                       atLevel:0];
            NSDebugMLLog(@"low",@"%@ _xmlDocument=\n%@",
                         [self logPrefix],
                         dumpString);
          };
#endif
          /*			  if (node->type!=XML_DTD_NODE)
                                  {
                                  NSLog(@"Bad first node type: %@ instead of %@",
                                  [nodeTypes objectForKey:[NSString stringWithFormat:@"%d",(int)node->type]],
                                  [nodeTypes objectForKey:[NSString stringWithFormat:@"%d",(int)XML_DTD_NODE]]);
                                  };
          */
          NSDebugMLog(@"Test Root");
          if ([node type]!=XML_ELEMENT_NODE)
            node=[node children];
          NSDebugMLog(@"Test Root children");
          NSAssert1(node,@"%@ Empty Document ([root children])",
                    [self logPrefix]);
          if ([node type]!=XML_ELEMENT_NODE)
            node=[node next];
          NSDebugMLog(@"Test Root children Next");
          NSAssert1(node,@"%@ Empty Document ([[root children] next])",
                    [self logPrefix]);
          if (node)
            {
              NSDebugMLog(@"Call createElementsFromNode:");
              NS_DURING
                {
                  elements=[self createElementsFromNode:node];			
                }
              NS_HANDLER
                {
                  LOGError(@"%@ Exception in elements creation!",
                           [self logPrefix]);
                  localException=ExceptionByAddingUserInfoObjectFrameInfo(localException,
                                                                          @"%@ - Exception in elements creation",
                                                                          [self logPrefix]);
                  [localException retain];
                  [localException autorelease];
                  [localException raise];
                }
              NS_ENDHANDLER;
            };
        };
    };
  LOGObjectFnStop();
  return elements;
};

//--------------------------------------------------------------------

/*
text [Type:XML_TEXT_NODE] [{}] ####
head [Type:XML_ELEMENT_NODE] [{}] ##(null)##
        title [Type:XML_ELEMENT_NODE] [{}] ##(null)##
                text [Type:XML_TEXT_NODE] [{}] ##MyTitle##
text [Type:XML_TEXT_NODE] [{}] ####
body [Type:XML_ELEMENT_NODE] [{bgcolor = white; }] ##(null)##
        text [Type:XML_TEXT_NODE] [{}] ####
        gsweb [Type:XML_ELEMENT_NODE] [{name = MyObject; }] ##(null)##
                text [Type:XML_TEXT_NODE] [{}] ##AText##
                p [Type:XML_ELEMENT_NODE] [{align = center; }] ##(null)##
                        text [Type:XML_TEXT_NODE] [{}] ##Text2##
                        b [Type:XML_ELEMENT_NODE] [{}] ##(null)##
                                text [Type:XML_TEXT_NODE] [{}] ##Text3##
                text [Type:XML_TEXT_NODE] [{}] ####
        text [Type:XML_TEXT_NODE] [{}] ##TEXTB##
        comment [Type:XML_COMMENT_NODE] [{}] ##MyComment##
        text [Type:XML_TEXT_NODE] [{}] ##TEXTC##
text [Type:XML_TEXT_NODE] [{}] ####
*/
-(NSArray*)createElementsFromNode:(GSXMLNode*)node
{
  GSXMLNode* currentNode=node;
  NSMutableArray* _elements=nil;
  NSAutoreleasePool* arp = nil;
  LOGObjectFnStart();
  _elements=[NSMutableArray array];
  arp=[NSAutoreleasePool new];
  while(currentNode)
    {
      GSWElement* elem=nil;
      NSDebugMLog(@"BEGIN node=%p %@ [Type:%@] [%@] ##%@##\n",
                  currentNode,
                  [currentNode name],
                  [currentNode typeDescription],
                  [currentNode propertiesAsDictionary],
                  [currentNode content]);
      switch([currentNode type])
        {
        case XML_TEXT_NODE:
          {
            elem=[GSWHTMLBareString elementWithString:[currentNode content]];
            NSDebugMLog(@"TEXT element=%@",elem);
          };
          break;
        case XML_COMMENT_NODE:
          {
            elem=[GSWHTMLBareString elementWithString:[currentNode content]];
            NSDebugMLog(@"COMMENT element=%@",elem);
          };
          break;
        default:
          {
            NSArray* children=nil;
            NSDictionary* nodeAttributes=nil;
            NSString* nodeName=nil;
            NSString* nodeNameAttribute=nil;
            nodeName=[currentNode name];
            NSDebugMLog(@"DEFAULT (%@)",nodeName);
            if ([currentNode children])
              {
                children=[self createElementsFromNode:[currentNode children]];
                NSDebugMLog(@"node=%p children=%@",currentNode,children);
              };
            //if (currentNode->type==XML_ELEMENT_NODE)
            {
              nodeAttributes=[currentNode propertiesAsDictionaryWithKeyTransformationSel:@selector(lowercaseString)];
              nodeNameAttribute=[nodeAttributes objectForKey:@"name"];
              NSDebugMLog(@"node=%p nodeAttributes=%@",currentNode,nodeAttributes);
              NSDebugMLog(@"node=%p nodeNameAttribute=%@",currentNode,nodeNameAttribute);
              if ([nodeName caseInsensitiveCompare:@"gsweb"]==NSOrderedSame)
                {
                  GSWPageDefElement* definitionsElement=nil;
                  if (!nodeNameAttribute)
                    {
                      ExceptionRaise(@"GSWTemplateParser",
                                     @"%@ No element name for gsweb tag",
                                     [self logPrefix]);
                    }
                  else
                    {
                      definitionsElement=[_definitions objectForKey:nodeNameAttribute];
                      NSDebugMLLog(@"low",@"definitionsElement:[%@]",
                                   definitionsElement);
                      NSDebugMLLog(@"low",@"GSWeb Tag definitionsElement:[%@]",
                                   definitionsElement);
                      if (!definitionsElement)
                        {
                          ExceptionRaise(@"GSWTemplateParser",
                                         @"%@ No element definition for tag named:%@",
                                         [self logPrefix],
                                         nodeNameAttribute);
                        }
                      else
                        {
                          NSDictionary* _associations=[definitionsElement associations];
                          NSString* className=[definitionsElement className];
                          NSDebugMLLog(@"low",@"node=%p GSWeb Tag className:[%@]",currentNode,className);
                          if (!className)
                            {
                              ExceptionRaise(@"GSWTemplateParser",
                                             @"%@No class name in page definition for tag named:%@ definitionsElement=%@",
                                             [self logPrefix],
                                             nodeNameAttribute,
                                             definitionsElement);
                            }
                          else
                            {
                              NSDebugMLLog(@"low",@"node=%p associations:%@",currentNode,_associations);
                              {
                                NSEnumerator* _nodeAttributesEnum = [nodeAttributes keyEnumerator];
                                id _tagAttrKey=nil;
                                id _tagAttrValue=nil;
                                NSMutableDictionary* _addedAssoc=nil;
                                while ((_tagAttrKey = [_nodeAttributesEnum nextObject]))
                                  {
                                    if (![_tagAttrKey isEqualToString:@"name"] && ![_associations objectForKey:_tagAttrKey])
                                      {
                                        if (!_addedAssoc)
                                          _addedAssoc=(NSMutableDictionary*)[NSMutableDictionary dictionary];
                                        _tagAttrValue=[nodeAttributes objectForKey:_tagAttrKey];
                                        [_addedAssoc setObject:[GSWAssociation associationWithValue:_tagAttrValue]
                                                     forKey:_tagAttrKey];
                                      };
                                  };
                                if (_addedAssoc)
                                  {
                                    _associations=[_associations dictionaryByAddingEntriesFromDictionary:_addedAssoc];
                                  };
                              };
                              NSDebugMLog(@"node=%p gsweb name=%@ dynamicElementWithName: children=%@",
                                          currentNode,
                                          nodeNameAttribute,
                                          children);
                              NSDebugMLog(@"node=%p %@ [Type:%@] [%@] ##%@##\n",
                                          currentNode,
                                          [currentNode name],
                                          [currentNode typeDescription],
                                          [currentNode propertiesAsDictionary],
                                          [currentNode content]);
                              elem=[GSWApp dynamicElementWithName:className
                                           associations:_associations
                                           template:[[[GSWHTMLStaticGroup alloc]initWithContentElements:children]autorelease]
                                           languages:_languages];
                              NSDebugMLog(@"node=%p element=%@",currentNode,elem);
                              if (!elem)
                                {
                                  ExceptionRaise(@"GSWTemplateParser",
                                                 @"%@ Creation failed for element named:%@ className:%@",
                                                 [self logPrefix],
                                                 [definitionsElement elementName],
                                                 className);
                                };
                            };
                        };
                    };
                }
              else
                {
                  NSDictionary* _associations=nil;
                  NSEnumerator* _nodeAttributesEnum = [nodeAttributes keyEnumerator];
                  id _tagAttrKey=nil;
                  id _tagAttrValue=nil;
                  NSMutableDictionary* _addedAssoc=nil;
                  NSDebugMLog(@"node=%p Create nodeName=%@",currentNode,nodeName);
                  while ((_tagAttrKey = [_nodeAttributesEnum nextObject]))
                    {
                      if (![_tagAttrKey isEqualToString:@"name"] && ![_associations objectForKey:_tagAttrKey])
                        {
                          if (!_addedAssoc)
                            _addedAssoc=(NSMutableDictionary*)[NSMutableDictionary dictionary];
                          _tagAttrValue=[nodeAttributes objectForKey:_tagAttrKey];
                          [_addedAssoc setObject:[GSWAssociation associationWithValue:_tagAttrValue]
                                       forKey:_tagAttrKey];
                        };
                    };
                  if (_addedAssoc)
                    {
                      _associations=[NSDictionary dictionaryWithDictionary:_addedAssoc];
                    };
                  NSDebugMLog(@"node=%p StaticElement: children=%@",currentNode,children);
                  elem=[[[GSWHTMLStaticElement alloc]initWithName:nodeName
                                                     attributeDictionary:_associations
                                                     contentElements:children]autorelease];
                  NSDebugMLog(@"node=%p element=%@",currentNode,elem);
                };
            };
          };
          break;
        };
      [_elements addObject:elem];
      NSDebugMLog(@"END node=%p %@ [Type:%@] [%@] ##%@##\n",
                  currentNode,
                  [currentNode name],
                  [currentNode typeDescription],
                  [currentNode propertiesAsDictionary],
                  [currentNode content]);
      currentNode=[currentNode next];
    };
  DESTROY(arp);
  LOGObjectFnStop();
  NSDebugMLog(@"_elements=%@",_elements);
  return _elements;
};

@end


//====================================================================
// used only for XML/XMLHTML differences
@implementation GSWTemplateParserXMLHTML

@end