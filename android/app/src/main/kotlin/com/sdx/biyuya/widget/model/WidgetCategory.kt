package com.sdx.biyuya.widget.model

import org.json.JSONArray
import org.json.JSONObject

/**
 * Represents a category in the expense widget.
 * Mirrors the Flutter Category entity for widget display.
 */
data class WidgetCategory(
    val id: Int,
    val name: String,
    val color: String?,   // hex string like "#FF0000"
    val icon: String?     // Material icon code point as string
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("id", id)
        put("name", name)
        put("color", color ?: "")
        put("icon", icon ?: "")
    }

    companion object {
        fun fromJson(json: JSONObject): WidgetCategory = WidgetCategory(
            id = json.getInt("id"),
            name = json.getString("name"),
            color = json.optString("color", "").ifEmpty { null },
            icon = json.optString("icon", "").ifEmpty { null }
        )

        fun listToJson(categories: List<WidgetCategory>): String {
            val array = JSONArray()
            categories.forEach { array.put(it.toJson()) }
            return array.toString()
        }

        fun listFromJson(jsonString: String): List<WidgetCategory> {
            if (jsonString.isBlank() || jsonString == "[]") return emptyList()
            return try {
                val array = JSONArray(jsonString)
                (0 until array.length()).map { i ->
                    fromJson(array.getJSONObject(i))
                }
            } catch (e: Exception) {
                emptyList()
            }
        }
    }
}
