#--
# Copyright (c) 2010-2011 Peter Horn, Provideal GmbH
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

module Tabulatr
  class Renderer
    module DataCell

      # the method used to actually define the data cells of the columns,
      # taking the name of the attribute and a hash of options.
      #
      # The following options are evaluated here:
      # <tt>:td_html</tt>:: a hash with html-attributes added to the <ts>s created
      # <tt>:method</tt>:: the actual method invoked on the record to retrieve the
      #                    value for the column, or false if name is to be used.
      # <tt>:fromat</tt>:: either a String by which the value is <tt>sprinf</tt>ed,
      #                    a proc/lambda to which the value is passed or false if
      #                    no specific formatting is desired.
      def data_column(name, opts={}, &block)
        raise "Not in data mode!" if @row_mode != :data
        opts = normalize_column_options(name, opts)
        make_tag(:td, opts[:td_html]) do
          href = if opts[:link].class == Symbol || opts[:link].class == String
              @view.send(opts[:link], @record)
            elsif opts[:link].respond_to?(:call)
              opts[:link].call(@record)
            else
              nil
            end
          make_tag((href ? :a : nil), :href => href) do
            if block_given?
              concat(@view.instance_exec(@record, &block))
            else
              val = @record.send(opts[:method] || name)
              format = opts[:format]
              concat(
                if format.is_a?(Proc) then @view.instance_exec(val, &format)
                elsif format.is_a?(String) then h(format % val)
                elsif format.is_a?(Symbol) then @view.send(format, val)
                else h(val.to_s)
              end)
            end # block_given?
          end # </a>
        end # </td>
      end

      # the method used to actually define the data cells of the columns,
      # taking the name of the attribute and a hash of options.
      #
      # The following options are evaluated here:
      # <tt>:td_html</tt>:: a hash with html-attributes added to the <ts>s created
      # <tt>:method</tt>:: the actual method invoked on the record to retrieve the
      #                    value for the column, or false if name is to be used.
      # <tt>:format</tt>:: either a String by which the value is <tt>sprinf</tt>ed,
      #                    a proc/lambda to which the value is passed or false if
      #                    no specific formatting is desired.
      def data_association(relation, name, opts={}, &block)
        raise "Not in data mode!" if @row_mode != :data
        opts = normalize_column_options(name, opts)
        if block_given?
          return @view.instance_exec(@record, &block)
        end
        assoc = @record.class.reflect_on_association(relation)
        make_tag(:td, opts[:td_html]) do
          format = opts[:format]
          ass = @record.send(relation.to_sym)
          if opts[:sort_by]
            # TODO: SORTING specified by opts[:sort_by]
          end
          concat(if (ass.is_a?(Array) || ass.respond_to?(:to_ary)) && (opts[:map] != false)
            ass.map do |r|
              val = h(r.send(opts[:method] || name))
              if format.is_a?(Proc) then format.call(val)
              elsif format.is_a?(String) then h(format % val)
              elsif format.is_a?(Symbol) then @view.send(format, val)
              else h(val.to_s)
              end
            end.join(opts[:join_symbol] || ', ')
          else
            return '' unless ass
            #puts ass.to_s
            val = h(ass.send(opts[:method] || name))
            val = if format.is_a?(Proc) then @view.instance_exec(val, &format)
            elsif format.is_a?(String) then h(format % val)
            elsif format.is_a?(Symbol) then @view.send(format, val)
            else h(val.to_s)
            end
          end)
        end # </td>
      end

      def data_checkbox(opts={}, &block)
        raise "Whatever that's for!" if block_given?
        iname = "#{@classname}_checked[current_page][]"
        make_tag(:td, opts[:td_html]) do
          checked = @checked[:selected].member?(@record.send(@id)) ? :checked : nil
          make_tag(:input, :type => 'checkbox', :name => iname,
            :id => "#{@classname}_checked_#{@record.send(@id).to_s}",
            :value => @record.send(@id), :checked => checked)
        end
      end

      def data_action(opts={}, &block)
        raise "Not in data mode!" if @row_mode != :data
        opts = normalize_column_options(:action_column, opts)
        make_tag(:td, opts[:td_html]) do
          if block_given?
            concat(yield(@record))
          else
            raise "Always give a block ino action columns"
          end # block_given?
        end # </td>
      end
    end
  end
end
