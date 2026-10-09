import { expect, test } from 'e2e';

test('adds a todo', async ({ app, agent, screen }) => {
  await app.open('/');
  await agent.act('add a todo named Buy milk');
  await expect(screen.getByRole('listitem')).toContainText('Buy milk');
  await expect(screen.getByRole('status')).toContainText('1 item');
});
