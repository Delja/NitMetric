# This file is part of NIT ( http://www.nitlanguage.org ).
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
# Detect the code smells and antipatterns in the code.

module codesmells_metrics

import frontend

import metrics_base
import mclasses_metrics
import semantize

import method_analyse_metrics
import mclassdef_collect


redef class ToolContext
	var codesmells_metrics_phase: Phase = new CodeSmellsMetricsPhase(self, null)
end

class CodeSmellsMetricsPhase
	super Phase

	var average_number_of_lines = 0.0
	var average_number_of_parameter = 0.0
	var average_number_of_method = 0.0
	var average_number_of_attribute = 0.0


	redef fun process_mainmodule(mainmodule, given_mmodules) do
		print toolcontext.format_h1("--- Code Smells Metrics ---")
		self.set_all_average_metrics
		var mclass_codesmell = new BadConceptions
		var collect = new Counter[MClassDef]
		var mclassdefs = new Array[MClassDef]

		for mclass in mainmodule.flatten_mclass_hierarchy do
			mclass_codesmell.collect(mclass.mclassdefs,self)
		end
		mclass_codesmell.print_all
	end

	fun set_all_average_metrics do
		var model_builder = toolcontext.modelbuilder
		var model_view = model_builder.model.private_view

		self.average_number_of_lines = model_view.get_avg_LineNumber(model_builder)
		self.average_number_of_parameter = model_view.get_avg_parameter
		self.average_number_of_method = model_view.get_avg_method(model_builder)
		self.average_number_of_attribute = model_view.get_avg_attribut(model_builder)
	end
end

class BadConceptions
	# Code smell list
	var bad_conception_element = new Array[BadConceptionClass]

	# Print all element conception
	fun print_all do
		for bad_conception in bad_conception_element do
			bad_conception.print_all
		end
	end

	# Print number of top element conception
	fun print_top(number: Int) do

	end

	# Collection
	fun collect(mclassdefs: Array[MClassDef],phase: CodeSmellsMetricsPhase) do
		for mclassdef in mclassdefs do
			var bad_conception_class = new BadConceptionClass(mclassdef,phase)
			bad_conception_class.collect
			bad_conception_element.add(bad_conception_class)
		end
	end
end

class BadConceptionClass
	var mclassdef: MClassDef
	var array_badconception = new Array[BadConception]
	var phase: CodeSmellsMetricsPhase

	init(mclassdef: MClassDef, phase: CodeSmellsMetricsPhase) do
		self.mclassdef = mclassdef
		self.phase = phase
	end

	fun collect do
		var bad_conception_elements = new Array[BadConception]
		bad_conception_elements.add(new LargeClass(phase))
		bad_conception_elements.add(new LongParameterList(phase))
		bad_conception_elements.add(new FeatureEnvy(phase))
		bad_conception_elements.add(new LongMethod(phase))
		for bad_conception_element in bad_conception_elements do
			var result = bad_conception_element.collect(self.mclassdef,phase.toolcontext.modelbuilder)
			if result == true then array_badconception.add(bad_conception_element)
		end
	end

	fun print_all do
		if array_badconception.length != 0 then
			print "-----------"
			print "{mclassdef.full_name}"
			for bad_conception in array_badconception do
				bad_conception.print_result
			end
		end
	end
end

class BadConception
	var phase: CodeSmellsMetricsPhase

	# Name
	fun name: String is abstract

	# Description
	fun desc: String is abstract

	# Collection method
	fun collect(mclassdef: MClassDef, model_builder: ModelBuilder): Bool is abstract

	# Show results in console
	fun print_result is abstract
end



class LargeClass
	super BadConception

	var number_attribut = 0

	var number_method = 0

	redef fun name do
		return "LARGC"
	end
	redef fun desc do
		return "Large class"
	end

	redef fun collect(mclassdef, model_builder): Bool do
		number_attribut = mclassdef.collect_intro_and_redef_mattributes(model_builder.model.private_view).length
		# get the number of methods and subtract the get and set of attibutes (numberAtribut*2)
		number_method = mclassdef.collect_intro_and_redef_methods(model_builder.model.private_view).length - (number_attribut*2)
		if number_method.to_f > phase.average_number_of_method and number_attribut.to_f > phase.average_number_of_attribute then
			return true
		end
		return false
	end

	redef fun print_result do
		print phase.toolcontext.format_h2("{desc}: {number_attribut} attributes and {number_method} methods ({phase.average_number_of_attribute}A {phase.average_number_of_method}M Average)")
	end
end

class LongParameterList
	super BadConception

	var bad_methods = new Array[MMethodDef]

	redef fun name do
		return "LONGPL"
	end
	redef fun desc do
		return "Long parameter list"
	end

	redef fun collect(mclassdef, model_builder): Bool do
		var result = false
		for meth in mclassdef.mpropdefs do
			# check if the property is a method definition
			if not meth isa MMethodDef then continue
			# Check if method has a signature
			if meth.msignature == null then continue
			if meth.msignature.mparameters.length <= 4 then continue
			bad_methods.add(meth)
			result = true
		end
		return result
	end


	redef fun print_result do
		print "{desc}:"
		if bad_methods.length >= 1 then
			print "	Affected method(s):"
			for method in bad_methods do
				print "		-{method.name} has {method.msignature.mparameters.length} parameters"
			end
		end
	end
end


class FeatureEnvy
	super BadConception

	var bad_methods = new Array[MMethodDef]

	redef fun name do
		return "FEM"
	end
	redef fun desc do
		return "Feature envy"
	end

	redef fun collect(mclassdef, model_builder): Bool do
		var result = false
		var mmethoddefs = call_analyze_methods(mclassdef,model_builder)
		for mmethoddef in mmethoddefs do
			if mmethoddef.total_extern_call <= mmethoddef.total_self_call then continue
			result = true
			bad_methods.add(mmethoddef)
		end
		return result
	end


	redef fun print_result do
		print "{desc}:"
		if bad_methods.length >= 1 then
			print "	Affected method(s):"
			for method in bad_methods do
				print "		-{method.name} {method.total_self_call}/{method.total_call}"
			end
		end
	end
end

class LongMethod
	super BadConception

	var bad_methods = new Array[MMethodDef]

	redef fun name do
		return "LONGMETH"
	end
	redef fun desc do
		return "Long method"
	end

	redef fun collect(mclassdef, model_builder): Bool do
		var result = false
		var mmethoddefs = call_analyze_methods(mclassdef,model_builder)
		for mmethoddef in mmethoddefs do
			if mmethoddef.line_number <= phase.average_number_of_lines.to_i then continue
			result = true
			bad_methods.add(mmethoddef)
		end
		return result
	end


	redef fun print_result do
		print "{desc}:  Average {phase.average_number_of_lines.to_i} lines"
		if bad_methods.length >= 1 then
			print "	Affected method(s):"
			for method in bad_methods do
				print "		-{method.name} has {method.line_number} lines"
			end
		end
	end
end

redef class ModelView
	fun get_avg_parameter: Float do
		var counter = new Counter[MMethodDef]
		for mclassdef in mclassdefs do
			for method in mclassdef.mpropdefs do
			# check if the property is a method definition
				if not method isa MMethodDef then continue
				#Check if method has a signature
				if method.msignature == null then continue
				if method.msignature.mparameters.length == 0 then continue
				counter[method] = method.msignature.mparameters.length
			end
		end
		return counter.avg + counter.std_dev
	end

	fun get_avg_attribut(model_builder: ModelBuilder): Float do
		var counter = new Counter[MClassDef]
		for mclassdef in mclassdefs do
			var numberAttribut = mclassdef.collect_intro_and_redef_mattributes(model_builder.model.private_view).length
			# numberAttribut += mclassdef.collect_inherited_mmethods.length
			if numberAttribut != 0 then counter[mclassdef] = numberAttribut
		end
		return counter.avg + counter.std_dev
	end

	fun get_avg_method(model_builder: ModelBuilder): Float do
		var counter = new Counter[MClassDef]
		for mclassdef in mclassdefs do
			var numberMethode = mclassdef.collect_intro_and_redef_methods(model_builder.model.private_view).length - (mclassdef.collect_intro_and_redef_mattributes(model_builder.model.private_view).length*2)
			if numberMethode != 0 then counter[mclassdef] = numberMethode
		end
		return counter.avg + counter.std_dev
	end

	fun get_avg_LineNumber(model_builder: ModelBuilder): Float do
		var methods_analyse_metrics = new Counter[MClassDef]
		for mclassdef in mclassdefs do
			var result = 0
			var count = 0
			for mmethoddef in call_analyze_methods(mclassdef,model_builder) do
				result += mmethoddef.line_number
				if mmethoddef.line_number == 0 then continue
				count += 1
			end
			if not mclassdef.collect_local_mproperties(model_builder.model.private_view).length != 0 then continue
			if count == 0 then continue
			methods_analyse_metrics[mclassdef] = (result/count).to_i
		end
		return methods_analyse_metrics.avg + methods_analyse_metrics.std_dev
	end
end