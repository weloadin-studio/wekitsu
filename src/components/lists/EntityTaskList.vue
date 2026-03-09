<template>
  <div class="data-list">
    <div>
      <table class="datatable" ref="headerWrapper">
        <thead class="datatable-head">
          <tr class="datatable-row-header">
            <th class="type">
              {{ $t('tasks.fields.task_type') }}
            </th>
            <th class="status">
              {{ $t('tasks.fields.task_status') }}
            </th>
            <th class="priority">
              {{ $t('task_types.fields.priority') || 'Priority' }}
            </th>
            <th class="estimation">
              {{ $t('tasks.fields.estimation').substring(0, 3) }}.
            </th>
            <th class="estimation">
              {{ $t('tasks.fields.duration').substring(0, 3) }}.
            </th>
            <th class="startdate">
              <div class="flexcolumn">
                <span class="flexrow-item">
                  {{ $t('tasks.fields.start_date_short') }}
                </span>
                <date-field
                  class="flexrow-item"
                  :model-value="null"
                  :with-margin="false"
                  @update:model-value="onBulkStartDateChange"
                />
              </div>
            </th>
            <th class="duedate">
              <div class="flexcolumn">
                <span class="flexrow-item">
                  {{ $t('tasks.fields.due_date') }}
                </span>
                <date-field
                  class="flexrow-item"
                  :model-value="null"
                  :with-margin="false"
                  @update:model-value="onBulkDueDateChange"
                />
              </div>
            </th>
            <th class="assignees">
              <div class="flexcolumn">
                <span class="flexrow-item">
                  {{ $t('tasks.fields.assignees') }}
                </span>
                <people-field
                  class="flexrow-item"
                  :people="projectTeamPeople"
                  @update:model-value="onBulkAssigneesChange"
                />
              </div>
            </th>
            <th class="end-cell"></th>
          </tr>
        </thead>
      </table>
    </div>

    <table-info :is-loading="isLoading" :is-error="isError" />

    <div
      class="task-list-body"
      @scroll.passive="onBodyScroll"
      v-if="entries.length > 0"
    >
      <table class="datatable">
        <tbody class="datatable-body">
          <tr
            :key="task.id"
            :class="{
              selected: currentTask && currentTask.id === task.id,
              'datatable-row': true,
              'datatable-row--selectable': true
            }"
            @click="selectTask(task)"
            v-for="task in sortedEntries"
          >
            <task-type-cell
              class="type"
              :task-type="getTaskType(task.id)"
              :production-id="currentProduction.id"
              :task-id="task.id"
              v-if="getTaskType(task.id)"
            />

            <!-- Status: inline ComboboxStatus dropdown -->
            <td class="status" @click.stop>
              <combobox-status
                v-if="getTask(task.id)"
                :model-value="getTask(task.id).task_status_id"
                :task-status-list="getTaskStatusList(task)"
                :narrow="true"
                :with-margin="false"
                :color-only="true"
                @update:model-value="onStatusChange(task, $event)"
              />
            </td>

            <!-- Priority: inline select -->
            <td class="priority" @click.stop v-if="getTask(task.id)">
              <select
                class="inline-input"
                :value="getTask(task.id).priority || 0"
                @change="
                  onPriorityChange(getTask(task.id), $event.target.value)
                "
              >
                <option value="0">{{ $t('tasks.priority.normal') }}</option>
                <option value="1">{{ $t('tasks.priority.high') }}</option>
                <option value="2">{{ $t('tasks.priority.very_high') }}</option>
                <option value="3">{{ $t('tasks.priority.emergency') }}</option>
              </select>
            </td>

            <!-- Estimation: inline number input -->
            <td class="estimation" @click.stop>
              <input
                class="inline-input"
                type="number"
                min="0"
                step="0.5"
                :value="task.estimation || ''"
                @change="onEstimationChange(task, $event.target.value)"
                @click.stop
              />
            </td>

            <!-- Duration: inline number input -->
            <td class="duration" @click.stop>
              <input
                class="inline-input"
                type="number"
                min="0"
                step="0.5"
                :value="task.duration || ''"
                @change="onDurationChange(task, $event.target.value)"
                @click.stop
              />
            </td>

            <!-- Start Date: inline DateField -->
            <td class="startdate" @click.stop>
              <date-field
                :model-value="task.start_date || null"
                :with-margin="false"
                :can-delete="true"
                :utc="true"
                @update:model-value="onStartDateChange(task, $event)"
              />
            </td>

            <!-- Due Date: inline DateField -->
            <td class="duedate" @click.stop>
              <date-field
                :model-value="task.due_date || null"
                :with-margin="false"
                :can-delete="true"
                :utc="true"
                @update:model-value="onDueDateChange(task, $event)"
              />
            </td>

            <!-- Assignees: PeopleField multiselect -->
            <td class="assignees" @click.stop>
              <div
                class="assignees-cell"
                v-if="!isCurrentUserClient && !isCurrentUserVendor"
              >
                <people-field
                  :multiple="true"
                  :people="projectTeamPeople"
                  :model-value="getAssigneeObjects(task)"
                  :clearable="false"
                  :small="true"
                  @select="onAssigneesChange(task, $event)"
                />
              </div>
            </td>

            <td class="end-cell"></td>
          </tr>
          <tr class="datatable-row total-row">
            <td>{{ $t('main.total') }}</td>
            <td>{{ entityProgress }}</td>
            <td></td>
            <td class="estimation">{{ formatDuration(entityEstimation) }}</td>
            <td class="duration">{{ formatDuration(entityDuration) }}</td>
            <td class="startdate">{{ entityStartDate }}</td>
            <td class="duedate">{{ entityDueDate }}</td>
            <td class="assignees">
              {{ entityAssignees.length }}
              {{ $tc('people.persons', entityAssignees.length) }}
            </td>
            <td class="end-cell"></td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'

import { formatListMixin } from '@/components/mixins/format'

import ComboboxStatus from '@/components/widgets/ComboboxStatus.vue'
import DateField from '@/components/widgets/DateField.vue'
import PeopleField from '@/components/widgets/PeopleField.vue'
import TableInfo from '@/components/widgets/TableInfo.vue'
import TaskTypeCell from '@/components/cells/TaskTypeCell.vue'

export default {
  name: 'entity-task-list',

  mixins: [formatListMixin],

  components: {
    ComboboxStatus,
    DateField,
    PeopleField,
    TableInfo,
    TaskTypeCell
  },

  props: {
    entries: {
      type: Array,
      default: () => []
    },
    isLoading: {
      type: Boolean,
      default: false
    },
    isError: {
      type: Boolean,
      default: false
    }
  },

  emits: ['task-selected'],

  data() {
    return {
      currentTask: null
    }
  },

  computed: {
    ...mapGetters([
      'activePeople',
      'currentProduction',
      'getTaskStatusForCurrentUser',
      'getTaskTypePriority',
      'isCurrentUserClient',
      'isCurrentUserVendor',
      'personMap',
      'taskMap',
      'taskStatusMap',
      'taskTypeMap'
    ]),

    sortedEntries() {
      return [...this.entries].sort((taskA, taskB) => {
        if (!taskA) return false
        const taskTypeA = this.taskTypeMap.get(taskA.task_type_id)
        const taskTypeB = this.taskTypeMap.get(taskB.task_type_id)
        const taskTypeAPriority = this.getTaskTypePriority(taskA.task_type_id)
        const taskTypeBPriority = this.getTaskTypePriority(taskB.task_type_id)
        if (taskTypeAPriority === taskTypeBPriority) {
          return taskTypeA.name.localeCompare(taskTypeB.name, undefined, {
            numeric: true
          })
        } else {
          return taskTypeAPriority - taskTypeBPriority
        }
      })
    },

    entityProgress() {
      const doneTasks = this.entries.filter(task => {
        const fullTask = this.getTask(task.id)
        const taskStatus = this.taskStatusMap.get(fullTask.task_status_id)
        return taskStatus.is_done
      })
      return `${doneTasks.length} / ${this.entries.length}`
    },

    entityEstimation() {
      return this.entries.reduce((acc, task) => acc + task.estimation, 0)
    },

    entityDuration() {
      return this.entries.reduce((acc, task) => acc + task.duration, 0)
    },

    entityStartDate() {
      if (this.entries.length === 0) return ''
      let startDate = this.entries[0].start_date
      this.entries.forEach(task => {
        if (task.start_date < startDate) {
          startDate = task.start_date
        }
      })
      return startDate ? startDate.substring(0, 10) : ''
    },

    entityDueDate() {
      if (this.entries.length === 0) return ''
      let dueDate = this.entries[0].due_date
      this.entries.forEach(task => {
        if (task.due_date > dueDate) {
          dueDate = task.due_date
        }
      })
      return dueDate ? dueDate.substring(0, 10) : ''
    },

    entityAssignees() {
      return [...new Set(this.entries.flatMap(task => task.assignees))]
    },

    projectTeamPeople() {
      const teamIds = new Set(this.currentProduction?.team || [])
      return this.activePeople.filter(p => teamIds.has(p.id))
    }
  },

  methods: {
    onBodyScroll(event) {
      const position = event.target
      this.$refs.headerWrapper.style.left = `-${position.scrollLeft}px`
    },

    getTask(task) {
      if (typeof task === 'string') {
        return this.taskMap.get(task)
      } else {
        return task
      }
    },

    getTaskType(entry) {
      const task = this.getTask(entry)
      return task ? this.taskTypeMap.get(task.task_type_id) : null
    },

    getAssignees(entry) {
      const task = this.getTask(entry)
      return task ? task.assignees : []
    },

    getAssigneeObjects(entry) {
      const task = this.getTask(entry.id) || entry
      if (!task || !task.assignees) return []
      return task.assignees.map(id => this.personMap.get(id)).filter(Boolean)
    },

    getTaskStatusList(task) {
      const fullTask = this.getTask(task.id) || task
      if (!fullTask) return []
      return this.getTaskStatusForCurrentUser(fullTask.project_id, false)
    },

    async onStatusChange(task, newStatusId) {
      const fullTask = this.getTask(task.id) || task
      if (!fullTask || newStatusId === fullTask.task_status_id) return
      try {
        await this.$store.dispatch('updateTask', {
          taskId: fullTask.id,
          data: { task_status_id: newStatusId }
        })
      } catch (error) {
        console.error('Failed to update task status:', error)
      }
    },

    async onPriorityChange(task, value) {
      const parsed = parseInt(value, 10)
      const priority = isNaN(parsed) ? 0 : parsed
      try {
        await this.$store.dispatch('updateTask', {
          taskId: task.id,
          data: { priority }
        })
      } catch (error) {
        console.error('Failed to update priority:', error)
      }
    },

    async onEstimationChange(task, value) {
      const parsed = parseFloat(value)
      const estimation = isNaN(parsed) ? 0 : parsed
      try {
        await this.$store.dispatch('updateTask', {
          taskId: task.id,
          data: { estimation }
        })
      } catch (error) {
        console.error('Failed to update estimation:', error)
      }
    },

    async onDurationChange(task, value) {
      const parsed = parseFloat(value)
      const duration = isNaN(parsed) ? 0 : parsed
      try {
        await this.$store.dispatch('updateTask', {
          taskId: task.id,
          data: { duration }
        })
      } catch (error) {
        console.error('Failed to update duration:', error)
      }
    },

    async onStartDateChange(task, value) {
      let start_date = null
      if (value) {
        start_date = this.formatLocalDate(value)
      }
      try {
        await this.$store.dispatch('updateTask', {
          taskId: task.id,
          data: { start_date }
        })
      } catch (error) {
        console.error('Failed to update start date:', error)
      }
    },

    async onDueDateChange(task, value) {
      let due_date = null
      if (value) {
        due_date = this.formatLocalDate(value)
      }
      try {
        await this.$store.dispatch('updateTask', {
          taskId: task.id,
          data: { due_date }
        })
      } catch (error) {
        console.error('Failed to update due date:', error)
      }
    },

    formatLocalDate(value) {
      // Use local date parts to avoid UTC offset shifting the date
      const d = value instanceof Date ? value : new Date(value)
      const year = d.getFullYear()
      const month = String(d.getMonth() + 1).padStart(2, '0')
      const day = String(d.getDate()).padStart(2, '0')
      return `${year}-${month}-${day}`
    },

    async onAssigneesChange(task, newPeopleArray) {
      const fullTask = this.getTask(task.id) || task
      if (!fullTask) return

      // PeopleField with multiple=true emits the full current array.
      // Diff old vs new to find who was added or removed.
      const currentIds = new Set(fullTask.assignees || [])
      const newIds = new Set((newPeopleArray || []).map(p => p.id))

      const added = [...newIds].filter(id => !currentIds.has(id))
      const removed = [...currentIds].filter(id => !newIds.has(id))

      try {
        for (const personId of added) {
          await this.$store.dispatch('assignSelectedTasks', {
            personId,
            taskIds: [fullTask.id]
          })
        }
        for (const personId of removed) {
          const person = this.personMap.get(personId)
          if (person) {
            await this.$store.dispatch('unassignPersonFromTask', {
              task: fullTask,
              person
            })
          }
        }
      } catch (error) {
        console.error('Failed to update assignees:', error)
      }
    },

    async onBulkStartDateChange(value) {
      if (!value) return
      const start_date = this.formatLocalDate(value)
      try {
        for (const task of this.entries) {
          const fullTask = this.getTask(task.id) || task
          await this.$store.dispatch('updateTask', {
            taskId: fullTask.id,
            data: { start_date }
          })
        }
      } catch (error) {
        console.error('Failed to bulk update start date:', error)
      }
    },

    async onBulkDueDateChange(value) {
      if (!value) return
      const due_date = this.formatLocalDate(value)
      try {
        for (const task of this.entries) {
          const fullTask = this.getTask(task.id) || task
          await this.$store.dispatch('updateTask', {
            taskId: fullTask.id,
            data: { due_date }
          })
        }
      } catch (error) {
        console.error('Failed to bulk update due date:', error)
      }
    },

    async onBulkAssigneesChange(person) {
      if (!person) return
      try {
        const taskIds = this.entries.map(
          task => (this.getTask(task.id) || task).id
        )
        await this.$store.dispatch('assignSelectedTasks', {
          personId: person.id,
          taskIds
        })
      } catch (error) {
        console.error('Failed to bulk assign person to tasks:', error)
      }
    },

    selectTask(task) {
      if (task.id === this.currentTask?.id) {
        this.currentTask = null
      } else {
        this.currentTask = task
      }
      this.$emit('task-selected', task)
    }
  }
}
</script>

<style lang="scss" scoped>
.data-list {
  max-width: 600px;
  margin-top: 0;

  .dark & {
    border: 0;
  }
}

.type {
  max-width: 250px;
  min-width: 250px;
}

.priority {
  max-width: 110px;
  min-width: 110px;
}

.estimation,
.duration {
  max-width: 70px;
  min-width: 70px;
  text-align: right;
}

.startdate,
.duedate {
  max-width: 130px;
  min-width: 130px;
  white-space: nowrap;
}

.status {
  max-width: 130px;
  min-width: 130px;
}

.assignees {
  max-width: 200px;
  min-width: 200px;
}

.end-cell {
  width: 100%;
}

.flexrow-item {
  margin-right: 0.3em;
}

.avatar-wrapper {
  margin-right: 0.5em;
}

.task-list-body {
  overflow-y: auto;
}

.datatable-row-header::after {
  display: none;
}

.total-row {
  border-bottom-left-radius: 10px;
  border-bottom-right-radius: 10px;
}

.inline-input {
  background: transparent;
  border: 1px solid transparent;
  border-radius: 4px;
  color: inherit;
  font-size: inherit;
  text-align: right;
  width: 100%;
  padding: 2px 4px;
  -moz-appearance: textfield;
  appearance: textfield;

  &::-webkit-outer-spin-button,
  &::-webkit-inner-spin-button {
    -webkit-appearance: none;
    appearance: none;
    margin: 0;
  }

  &:hover,
  &:focus {
    border-color: var(--border);
    outline: none;
    background: var(--background);
  }
}

.assignees-cell {
  width: 100%;
}
</style>
