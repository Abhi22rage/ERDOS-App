const { customAlphabet } = require('nanoid');

// Using a custom alphabet that is URL-friendly and easy to read
// Excludes confusing characters like 0, O, I, l
const alphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
const nanoid = customAlphabet(alphabet, 12);

/**
 * Prefixes for different entities in the PHED system
 */
const PREFIXES = {
  user: 'usr',
  session: 'ses',
  division: 'div',
  intake: 'brg', // Barge/Intake
  production_centre: 'pc',
  wtp: 'wtp',
  boosting_station: 'bst',
  component: 'cmp',
  component_unit: 'unt',
  pipeline: 'pipe',
  scheme: 'scm',
  beneficiary: 'ben',
  household: 'hhd',
  water_quality: 'wqr',
  revenue: 'rev',
  incident: 'inc', // Breakdown
  execution_stage: 'stg',
  media: 'med',
  contractor: 'con',
  work_order: 'wo',
  work_order_task: 'tsk',
  performance: 'perf',
  approval: 'appr',
  certificate: 'cert',
  history: 'hist',
  notification: 'ntf'
};

/**
 * Generates a prefixed NanoID
 * @param {string} entity - The entity type (e.g., 'user', 'wtp')
 * @returns {string} - A prefixed short ID like 'wtp_7A2k9P5m1R4'
 */
const generateId = (entity) => {
  const prefix = PREFIXES[entity];
  if (!prefix) {
    throw new Error(`Invalid entity type for ID generation: ${entity}`);
  }
  return `${prefix}_${nanoid()}`;
};

module.exports = {
  generateId,
  PREFIXES
};
