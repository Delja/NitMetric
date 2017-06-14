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
import method_analyze_metrics
import mclassdef_collect

redef class ToolContext
	var codesmells_metrics_phase = new CodeSmellsMetricsPhase(self, null)
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
		var mclass_codesmell = new BadConceptonController
		var collect = new Counter[MClassDef]
		var mclassdefs = new Array[MClassDef]

		for mclass in mainmodule.flatten_mclass_hierarchy do
			mclass_codesmell.collect(mclass.mclassdefs,self)
		end
		#mclass_codesmell.print_all
		mclass_codesmell.print_top(10)
	end

	fun set_all_average_metrics do
		var model_builder = toolcontext.modelbuilder
		var model_view = model_builder.model.private_view
		self.average_number_of_lines = model_view.get_avg_linenumber(model_builder)
		self.average_number_of_parameter = model_view.get_avg_parameter
		self.average_number_of_method = model_view.get_avg_method
		self.average_number_of_attribute = model_view.get_avg_attribut
	end
end

class BadConceptonController
	# Code smell list
	var bad_conception_elements = new Array[BadConceptionFinder]

	# Print all element conception
	fun print_all do
		for bad_conception in self.sort do
			bad_conception.print_collected_data
		end
	end

	# Print number of top element conception
	fun print_top(number: Int) do
		for bad_conception in self.get_numbers_of_elements(number) do
			bad_conception.print_collected_data
		end
	end

	# Collection
	fun collect(mclassdefs: Array[MClassDef],phase: CodeSmellsMetricsPhase) do
		for mclassdef in mclassdefs do
			var bad_conception_class = new BadConceptionFinder(mclassdef,phase)
			bad_conception_class.collect
			bad_conception_elements.add(bad_conception_class)
		end
	end

	fun sort: Array[BadConceptionFinder]
	do
		var res = bad_conception_elements
		var sorter = new BadConceptionComparator
		sorter.sort(res)
		return res
	end

	fun get_numbers_of_elements(number : Int) : Array[BadConceptionFinder]do
		var return_values = new Array[BadConceptionFinder]
		var list = self.sort
		var min = number
		if list.length <= number*2 then min = list.length
		for i in [0..min[ do
			var t = list[list.length-i-1]
			return_values.add(t)
		end
		return return_values
	end
end

class BadConceptionFinder
	var mclassdef: MClassDef
	var array_badconception = new Array[BadConception]
	var phase: CodeSmellsMetricsPhase
	var score = 0.0

	fun collect do
		var bad_conception_elements = new Array[BadConception]
		bad_conception_elements.add(new LargeClass(phase))
		bad_conception_elements.add(new LongParameterList(phase))
		bad_conception_elements.add(new FeatureEnvy(phase))
		bad_conception_elements.add(new LongMethod(phase))
		bad_conception_elements.add(new NoAbstractImplementation(phase))
		for bad_conception_element in bad_conception_elements do
			if bad_conception_element.collect(self.mclassdef,phase.toolcontext.modelbuilder) == true then array_badconception.add(bad_conception_element)
		end
		collect_global_score
	end

	fun print_collected_data do
		if array_badconception.length != 0 then
			print "--------------------"
			print phase.toolcontext.format_h1("{mclassdef.full_name}")
			for bad_conception in array_badconception do
				bad_conception.print_result
			end
		end
	end

	fun collect_global_score do
		if array_badconception.length != 0 then
			for bad_conception in array_badconception do
				self.score += bad_conception.score
			end
		end
	end
end

abstract class BadConception
	var phase: CodeSmellsMetricsPhase

	var score = 0.0

	# Name
	fun name: String is abstract

	# Description
	fun desc: String is abstract

	# Collection method
	fun collect(mclassdef: MClassDef, model_builder: ModelBuilder): Bool is abstract

	# Show results in console
	fun print_result is abstract

	# Show results in console
	fun score_calcul do
		score = 1.0
	end
end

class LargeClass
	super BadConception
	var number_attribut = 0

	var number_method = 0

	redef fun name do return "LARGC"

	redef fun desc do return "Large class"

	redef fun collect(mclassdef, model_builder): Bool do
		number_attribut = mclassdef.collect_intro_and_redef_mattributes(model_builder.model.private_view).length
		# get the number of methods (subtract the get and set of attibutes with (numberAtribut*2))
		number_method = mclassdef.collect_intro_and_redef_methods(model_builder.model.private_view).length
		score_calcul
		return number_method.to_f > phase.average_number_of_method and number_attribut.to_f > phase.average_number_of_attribute
	end

	redef fun print_result do
		print phase.toolcontext.format_h2("{desc}: {number_attribut} attributes and {number_method} methods ({phase.average_number_of_attribute}A {phase.average_number_of_method}M Average)")
	end

	redef fun score_calcul do
		#print "{(number_method.to_f + number_attribut.to_f) / (phase.average_number_of_method + phase.average_number_of_attribute)}"
		score = (number_method.to_f + number_attribut.to_f) / (phase.average_number_of_method + phase.average_number_of_attribute)
	end
end

class LongParameterList
	super BadConception
	var bad_methods = new Array[MMethodDef]

	redef fun name do return "LONGPL"

	redef fun desc do return "Long parameter list"

	redef fun collect(mclassdef, model_builder): Bool do
		for meth in mclassdef.collect_intro_and_redef_mpropdefs(model_builder.model.private_view) do
			# check if the property is a method definition
			if not meth isa MMethodDef then continue
			# Check if method has a signature
			if meth.msignature == null then continue
			if meth.msignature.mparameters.length <= 4 then continue
			bad_methods.add(meth)
		end
		score_calcul
		return bad_methods.not_empty
	end

	redef fun print_result do
		print phase.toolcontext.format_h2("{desc}:")
		if bad_methods.not_empty then
			print "	Affected method(s):"
			for method in bad_methods do
				print "		-{method.name} has {method.msignature.mparameters.length} parameters"
			end
		end
	end

	redef fun score_calcul do
		if bad_methods.not_empty then
			#print " LongParameterList {bad_methods.length.to_f / phase.average_number_of_method}"
			score = bad_methods.length.to_f / phase.average_number_of_method
		end
	end
end

class FeatureEnvy
	super BadConception
	var bad_methods = new Array[MMethodDef]

	redef fun name do return "FEM"

	redef fun desc do return "Feature envy"

	redef fun collect(mclassdef, model_builder): Bool do
		var mmethoddefs = call_analyze_methods(mclassdef,model_builder)
		for mmethoddef in mmethoddefs do
			var max_class_call = mmethoddef.class_call.max
			if mmethoddef.class_call[max_class_call] <= mmethoddef.total_self_call or max_class_call.mclass.full_name == mclassdef.mclass.full_name then continue
			bad_methods.add(mmethoddef)
		end
		score_calcul
		return bad_methods.not_empty
	end

	redef fun print_result do
		print phase.toolcontext.format_h2("{desc}:")
		if bad_methods.not_empty then
			print "	Affected method(s):"
			for method in bad_methods do
				var max_class_call = method.class_call.max
				if max_class_call != null then
					if max_class_call.mclass.mclass_type isa MGenericType then
						print "		-{method.name}({method.msignature.mparameters.to_s}) {method.total_self_call}/{method.class_call[max_class_call]}"
					else
						print "		-{method.name}({method.msignature.mparameters.to_s}) {method.total_self_call}/{method.class_call[max_class_call]} move to {max_class_call.mclass.full_name}"
					end
				end
			end
		end
	end

	redef fun score_calcul do
		if bad_methods.not_empty then
			#print " FeatureEnvy {bad_methods.length.to_f / phase.average_number_of_method}"
			score = bad_methods.length.to_f / phase.average_number_of_method
		end
	end
end

class LongMethod
	super BadConception
	var bad_methods = new Array[MMethodDef]

	redef fun name do return "LONGMETH"

	redef fun desc do return "Long method"

	redef fun collect(mclassdef, model_builder): Bool do
		var mmethoddefs = call_analyze_methods(mclassdef,model_builder)
		for mmethoddef in mmethoddefs do
			if mmethoddef.line_number <= phase.average_number_of_lines.to_i then continue
			bad_methods.add(mmethoddef)
		end
		return bad_methods.not_empty
	end

	redef fun print_result do
		print phase.toolcontext.format_h2("{desc}:  Average {phase.average_number_of_lines.to_i} lines")
		if bad_methods.not_empty then
			print "	Affected method(s):"
			for method in bad_methods do
				print "		-{method.name} has {method.line_number} lines"
			end
		end
	end

	redef fun score_calcul do
		if bad_methods.not_empty then
			#print " FeatureEnvy {bad_methods.length.to_f / phase.average_number_of_method}"
			score = bad_methods.length.to_f / phase.average_number_of_method
		end
	end
end

class NoAbstractImplementation
	super BadConception
	var bad_methods = new Array[MProperty]

	redef fun name do return "LONGMETH"

	redef fun desc do return "No Implemented abstract property"

	redef fun collect(mclassdef, model_builder): Bool do
		if mclassdef.collect_abstract_methods(model_builder.model.private_view).not_empty then
			bad_methods.add_all(mclassdef.collect_no_redef_propertys(mclassdef.collect_abstract_methods(model_builder.model.private_view),model_builder.model.private_view))
		end
		self.score_calcul
		return bad_methods.not_empty
	end

	redef fun print_result do
		print phase.toolcontext.format_h2("{desc}:")
		if bad_methods.not_empty then
			print "	Affected method(s):"
			for method in bad_methods do
				print "		-{method.name}"
			end
		end
	end

	redef fun score_calcul do
		if bad_methods.not_empty then
			#print " FeatureEnvy {bad_methods.length.to_f / phase.average_number_of_method}"
			score = bad_methods.length.to_f / phase.average_number_of_method
		end
	end
end

redef class ModelView
	fun get_avg_parameter: Float do
		var counter = new Counter[MMethodDef]
		for mclassdef in mclassdefs do
			for method in mclassdef.collect_intro_and_redef_mpropdefs(self) do
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

	fun get_avg_attribut: Float do
		var counter = new Counter[MClassDef]
		for mclassdef in mclassdefs do
			var number_attributs = mclassdef.collect_intro_and_redef_mattributes(self).length
			if number_attributs != 0 then counter[mclassdef] = number_attributs
		end
		return counter.avg + counter.std_dev
	end

	fun get_avg_method: Float do
		var counter = new Counter[MClassDef]
		for mclassdef in mclassdefs do
			var number_methodes = mclassdef.collect_intro_and_redef_methods(self).length
			if number_methodes != 0 then counter[mclassdef] = number_methodes
		end
		return counter.avg + counter.std_dev
	end

	fun get_avg_linenumber(model_builder: ModelBuilder): Float do
		var methods_analyse_metrics = new Counter[MClassDef]
		for mclassdef in mclassdefs do
			var result = 0
			var count = 0
			for mmethoddef in call_analyze_methods(mclassdef,model_builder) do
				result += mmethoddef.line_number
				if mmethoddef.line_number == 0 then continue
				count += 1
			end
			if not mclassdef.collect_local_mproperties(self).length != 0 then continue
			if count == 0 then continue
			methods_analyse_metrics[mclassdef] = (result/count).to_i
		end
		return methods_analyse_metrics.avg + methods_analyse_metrics.std_dev
	end
end

class BadConceptionComparator
	super Comparator
	redef type COMPARED: BadConceptionFinder
	redef fun compare(a,b) do
		var test = a.array_badconception.length <=> b.array_badconception.length
		if test == 0 then
			return a.score <=> b.score
		end
		return a.array_badconception.length <=> b.array_badconception.length
	end
end