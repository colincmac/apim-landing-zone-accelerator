metadata description = 'Reference: https://github.com/Azure/ARO-Landing-Zone-Accelerator/blob/87a5cedc63fc822ff7b2cadac1f650614e696a3f/Scenarios/Secure-Baseline/bicep/common-modules/naming/functions.bicep'

/* -------------------------------------------------------------------------- */
/*                                   IMPORTS                                  */
/* -------------------------------------------------------------------------- */

import { resourceTypeType, locationType } from 'types.bicep'

/* -------------------------------------------------------------------------- */
/*                              PRIVATE FUNCTIONS                             */
/* -------------------------------------------------------------------------- */

@description('Returns the string value with a hyphen prefix if provided, otherwise returns an empty string.')
func getStringLeadingWithHyphen(value string?) string => empty(value) ? '' : '-${value!}'

@description('Returns the abbreviations object that represents all resource abbreviation.')
func getResourceTypeAbbreviations() object => loadJsonContent('abbreviations.json')

@description('Returns the abbreviation for the provided resource type. If the abbreviation is not found, returns "unknown".')
func getResourceTypeAbbreviation(resourceType resourceTypeType) string => getResourceTypeAbbreviations()[resourceType!] ?? 'unknown'

@description('Returns the locations object that represents all locations.')
func getShortLocations() object => loadJsonContent('locations.json')

@description('Returns the location abbreviation for the provided location. If the abbreviation is not found, returns "unknown".')
func getShortLocation(location string) string => getShortLocations()[location] ?? 'unknown'

@description('Returns the length of the provided string. If the string is null, returns 0.')
func getStringLength(value string?) int => value == null ? 0 : length(value!)

@description('Returns a positive integer or zero based on the provided value.')
func getPositiveOrZeroInt(value int) int => value < 0 ? 0 : value

@description('Returns the remaining length based on the provided maximum length and the lenghts to remove. If the remaining length is negative, returns 0.')
func getRemainingLength(maxLength int, lenghts int[]) int => getPositiveOrZeroInt(maxLength - sys.reduce(lenghts, 0, (current, next) => current + next))

@description('Returns the remaining length of the resource name based on the provided parameters. If the hash is not provided, it used `uniqueStringSize` instead.')
func getRemainingLengthOfResource(maxLength int, abbreviation string, workloadName string, env string, location locationType, postfix string?, hash string?, uniqueStringSize int) int => getRemainingLength(maxLength, [getStringLength(abbreviation), getStringLength(workloadName), getStringLength(env), getStringLength(getShortLocation(location)), getStringLength(postfix), hash == null ? uniqueStringSize : getStringLength(hash)])

@description('Returns the hash if provided, otherwise returns a unique string based on the provided array of strings, limited to the provided length.')
func getHashOrGenerateUniqueString(hash string?, arrayForUniqueString string[]?, uniqueStringLength int) string => hash ?? take(uniqueString(join(arrayForUniqueString!, '_')), uniqueStringLength)

@description('Generates an array of strings that collectively form a unique global name for a resource. This function is designed to ensure that the generated name adheres to length constraints and includes meaningful parts such as resource type abbreviation, workload name, environment, location, an optional postfix and hash or a unique string. If the hash is not set, it generates a unique string based on a given array of strings. ')
func generateGloballyUniqueResourceNameParts(resourceType resourceTypeType, workloadName string, env string, location locationType, postfix string?, hash string?, arrayForUniqueString string[]?, uniqueStringLength int, maxLength int, separatePartsWithHypen bool) array => [
  getResourceTypeAbbreviation(resourceType)
  // Reduce the size of the workload to ensure that it does not exceed the remaining length.
  // If the remaining length is 0, the function `take` will return an empty string.
  // If the parts of the resource name are separated with a hyphen,
  // the length is recalculated to include the amount of hyphen characters.
  // Only the postfix can be null, so the length is recalculated to include the length of the postfix.
  take(toLower(workloadName), getRemainingLengthOfResource(separatePartsWithHypen ? (postfix == null ? maxLength - 4 : maxLength - 5) : maxLength, getResourceTypeAbbreviation(resourceType), workloadName, env, location, postfix, hash, uniqueStringLength))
  toLower(env)
  getShortLocation(location)
  toLower(postfix ?? '')
  getHashOrGenerateUniqueString(hash, arrayForUniqueString, uniqueStringLength)
]

@description('Concatenates the provided array of strings into a single string. If the `separatePartsWithHypen` parameter is set to true, the parts are separated with a hyphen.')
func concatenateGloballyUniqueResourceNameParts(parts array, separatePartsWithHypen bool) string => separatePartsWithHypen ? join(filter(parts, part => !empty(part)), '-') : join(filter(parts, part => !empty(part)), '')

/* -------------------------------------------------------------------------- */
/*                              PUBLIC FUNCTIONS                              */
/* -------------------------------------------------------------------------- */

@export()
@description('Generates a resource name that follows the convention: <resource-type-abbreviation>-<workload-name>-<lower-case-env>-<location-short>[-<postfix>][-<hash>].')
func generateResourceName(resourceType resourceTypeType, workloadName string, env string, location locationType, postfix string?, hash string?) string => '${getResourceTypeAbbreviation(resourceType)}-${toLower(workloadName)}-${toLower(env)}-${getShortLocation(location)}${getStringLeadingWithHyphen(postfix)}${getStringLeadingWithHyphen(hash)}'

@export()
@description('Generates a unique global resource name based on the provided parameters. The name is generated by concatenating the resource type abbreviation, workload name, environment, location, an optional postfix, and hash or a unique string. The function ensures that the generated name adheres to length constraints and includes meaningful parts. If the workload name is too long, it is reduced to fit the remaining length. If the postfix is too long, the end of the resource name is truncated to fit the maximum length `maxLength`. The different parts of the resource name can be separated with a hyphen if the `separatePartsWithHypen` parameter is set to true. If the hash is not set, a unique string is generated based on the provided array of strings with a maximum length of `uniqueStringLength`.')
func generateUniqueGlobalName(resourceType resourceTypeType, workloadName string, env string, location locationType, postfix string?, hash string?, arrayForUniqueString string[]?, uniqueStringLength int, maxLength int, separatePartsWithHypen bool) string => take(concatenateGloballyUniqueResourceNameParts(generateGloballyUniqueResourceNameParts(resourceType, separatePartsWithHypen ? workloadName : replace(workloadName, '-', ''), env, location, postfix, hash, arrayForUniqueString, uniqueStringLength, maxLength, separatePartsWithHypen), separatePartsWithHypen), maxLength)
