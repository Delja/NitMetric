# This file is part of NIT ( http://www.nitlanguage.org ).
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Helpers for various statistics tools.
module nitsmell_toolcontext

import modelbuilder
import csv
import counter
import console

redef class ToolContext

	# --all
	var opt_all = new OptionBool("Compute all code smells", "--all")
	# --mmodules
	var opt_feature_envy = new OptionBool("Compute feature envy", "--feature-envy")
	# --mclassses
	var opt_long_method = new OptionBool("Compute long method", "--long-methods")
	# --dir
	var opt_long_method_threshold = new OptionString("Directory where some statistics files are generated", "--long-method-threshold" , "-lmt")
	# --dir
	var opt_long_params_threshold = new OptionString("Directory where some statistics files are generated", "--long-params-threshold" , "-lpt")
	# --no-colors
	var opt_nocolors = new OptionBool("Disable colors in console outputs", "--no-colors")

	redef init
	do
		super
		self.option_context.add_option(opt_all)
		self.option_context.add_option(opt_feature_envy)
		self.option_context.add_option(opt_long_method)
		self.option_context.add_option(opt_long_method_threshold)
		self.option_context.add_option(opt_long_params_threshold)
		self.option_context.add_option(opt_nocolors)
	end

	# Format and colorize a string heading of level 1 for console output.
	#
	# Default style is yellow and bold.
	fun format_h1(str: String): String do
		if opt_nocolors.value then return str
		return str.yellow.bold
	end

	# Format and colorize a string heading of level 2 for console output.
	#
	# Default style is white and bold.
	fun format_h2(str: String): String do
		if opt_nocolors.value then return str
		return str.bold
	end

	# Format and colorize a string heading of level 3 for console output.
	#
	# Default style is white and nobold.
	fun format_h3(str: String): String do
		if opt_nocolors.value then return str
		return str
	end

	# Format and colorize a string heading of level 4 for console output.
	#
	# Default style is green.
	fun format_h4(str: String): String do
		if opt_nocolors.value then return str
		return str.green
	end

	# Format and colorize a string heading of level 5 for console output.
	#
	# Default style is light gray.
	fun format_p(str: String): String do
		if opt_nocolors.value then return str
		return str.light_gray
	end
end