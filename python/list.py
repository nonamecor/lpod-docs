# -*- coding: UTF-8 -*-
# Copyright (C) 2009 Itaapy, ArsAperta, Pierlis, Talend

# Import from lpod
from xmlpart import register_element_class, odf_element
from xmlpart import PREV_SIBLING, NEXT_SIBLING
from document import odf_create_list_item


def get_parent_item(element):
        while element.get_name() != 'text:list-item':
            element = element.get_parent()
        return element



class odf_list(odf_element):
    """Specialised element for lists.
    """

    def get_item_list_by_content(self, regex):
        paragraphs = self.get_element_list('//text:p')
        return [get_parent_item(paragraph) for paragraph in paragraphs
                                               if paragraph.match(regex)]

    def get_item_by_content(self, regex):
        items = self.get_item_list_by_content(regex)
        if items:
            return items[0]
        return None


    def insert_item(self, item, position=None, before=None, after=None):
        # Check if the item is already a list-item
        tag_name = item.get_name() if isinstance(item, odf_element) else None
        if tag_name != 'text:list-item':
            item = odf_create_list_item(item)

        if before is not None:
            before.insert_element(item, xmlposition=PREV_SIBLING)
        elif after is not None:
            after.insert_element(item, xmlposition=NEXT_SIBLING)
        elif position is not None:
            self.insert_element(item, position=position)
        else:
            raise ValueError, "position must be defined"


    def append_item(self, item):
        # Check if the item is already a list-item
        tag_name = item.get_name() if isinstance(item, odf_element) else None
        if tag_name != 'text:list-item':
            item = odf_create_list_item(item)
        self.append_element(item)


    def get_formated_text(self, context):
        result = u''
        for list_item in self.get_element_list('text:list-item'):
            text = u''
            for children in list_item.get_children():
                text += children.get_formated_text(context)
            text = text.strip('\n')
            # Indent the text
            text = u'- %s\n' % text.replace(u'\n', u'\n  ')
            result += text
        return result



register_element_class('text:list', odf_list)
