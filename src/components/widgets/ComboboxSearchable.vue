<template>
  <div :class="{ field: withMargin, 'is-inline': isInline }">
    <label class="label" v-if="label.length > 0">
      {{ label }}
    </label>
    <multiselect
      :options="options"
      :model-value="selectedOption"
      @update:model-value="updateValue"
      label="label"
      track-by="value"
      :searchable="true"
      :show-labels="false"
      :disabled="disabled"
      :loading="isLoading"
      :placeholder="placeholder"
      :allow-empty="true"
    >
      <template #noResult>
        {{ $t('main.no_results') || 'No results found' }}
      </template>
    </multiselect>
  </div>
</template>

<script>
import Multiselect from 'vue-multiselect'
import 'vue-multiselect/dist/vue-multiselect.min.css'

export default {
  name: 'combobox-searchable',

  components: {
    Multiselect
  },

  props: {
    label: { default: '', type: String },
    modelValue: { default: '', type: [String, Number, Boolean, Object] },
    options: { default: () => [], type: Array },
    disabled: { default: false, type: Boolean },
    withMargin: { default: true, type: Boolean },
    isInline: { default: false, type: Boolean },
    isLoading: { default: false, type: Boolean },
    placeholder: { default: 'Select option...', type: String }
  },

  emits: ['update:modelValue', 'change'],

  computed: {
    selectedOption() {
      return this.options.find(o => o.value === this.modelValue) || null
    }
  },

  methods: {
    updateValue(option) {
      const val = option ? option.value : null
      this.$emit('update:modelValue', val)
      this.$emit('change', val)
    }
  }
}
</script>

<style lang="scss" scoped>
.field .label {
  padding-top: 5px;
  margin-bottom: 0.25em;
}
</style>
