import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

test('contract comparison accepts reordered inventory and blocks real removals or missing acceptance', t => {
  fs.mkdirSync(path.join(root, 'target'), { recursive:true });
  const fixture = fs.mkdtempSync(path.join(root, 'target/contract drift '));
  t.after(() => fs.rmSync(fixture, { recursive:true, force:true }));
  for (const directory of ['ops/ci', 'schemas', 'contracts']) fs.mkdirSync(path.join(fixture, directory), {recursive:true});
  for (const script of ['lib.sh', 'contract-drift.sh']) fs.copyFileSync(path.join(root, 'ops/ci', script), path.join(fixture, 'ops/ci', script));
  const baseline = path.join(fixture, 'contracts/contract-inventory.txt');
  const source = path.join(fixture, 'schemas/proof-plan.schema.json');
  fs.writeFileSync(source, '{}\n');
  fs.writeFileSync(path.join(fixture, 'schemas/proof.json'), '{}\n');
  fs.writeFileSync(baseline, 'schemas/proof.json\nschemas/proof-plan.schema.json\n');
  const run = () => {
    const result = spawnSync('bash', ['ops/ci/contract-drift.sh'], {cwd:fixture, encoding:'utf8'});
    assert.ifError(result.error);
    return result;
  };
  let result = run();
  assert.equal(result.status, 0, result.stderr);
  fs.unlinkSync(source);
  result = run();
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /breaking contract removal[\s\S]*schemas\/proof-plan.schema.json/);
  fs.writeFileSync(source, '{}\n');
  fs.writeFileSync(baseline, '');
  assert.notEqual(run().status, 0);
  fs.unlinkSync(baseline);
  assert.notEqual(run().status, 0);
});

test('full and local quality recipes both execute contract drift', () => {
  for (const name of ['github-check.sh', 'quality-gates.sh']) {
    assert.match(fs.readFileSync(path.join(root, 'ops/ci', name), 'utf8'), /^bash ops\/ci\/contract-drift\.sh$/m);
  }
});
